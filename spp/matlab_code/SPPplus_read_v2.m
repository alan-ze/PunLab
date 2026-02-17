function [time_wave,resp_wave,L,fname_t] = SPPplus_read_v2(fname,ftype,var_loc,...
    var_conv,data_trunc)
% This function reads data from the selected file, and performs any
% necessary unit conversions.
    %Inputs: fname = name of file to read (as a string)
            %ftype = type of file being read
                %1 -> .txt file 
                %2 -> .csv file
            %var_loc = vactor of column positions to read
            %var_conv = vector of unit conversion factors
    %Outputs: time_wave = Lx1 vector of time at each measurement point
            %resp_wave = Lx3 matrix of the strain, rate and stress data,
                %with each row representing a measuring point
            %L = number of measurement points in the extracted data

is_diff = (var_loc(3)==0); % does rate need to be differentiated?

%Extract data from file
if ftype == 1
    f_name = sprintf('%s.txt',fname);
    FID = fopen(f_name,'r');
    if is_diff == 1
        datacell = textscan(FID, '%f %f %f','HeaderLines', 0,'CollectOutput',1);
    else
        datacell = textscan(FID, '%f %f %f %f','HeaderLines', 0,'CollectOutput',1);
    end
    fclose(FID);
    a_temp=datacell{1};
    A=nan(size(a_temp,1),4);
    A(:,[1,2,4])=[a_temp(:,var_loc(1))*var_conv(1),...
        a_temp(:,var_loc(2))*var_conv(2),a_temp(:,var_loc(4))*var_conv(4)];
    if is_diff == 0
        A(:,3)=a_temp(:,var_loc(3))*var_conv(3);
    end
elseif ftype == 2
    f_name = sprintf('%s.csv',fname);
    a_temp=readmatrix(f_name);  % readmatrix for linux
    a_temp_cut=nan(size(a_temp,1),4);
    a_temp_cut(:,[1,2,4])=[a_temp(:,var_loc(1))*var_conv(1),...
        a_temp(:,var_loc(2))*var_conv(2),a_temp(:,var_loc(4))*var_conv(4)];
    if is_diff == 0
        a_temp_cut(:,3)=a_temp(:,var_loc(3))*var_conv(3);
    end
    A=[];
    for nn=1:size(a_temp,1)
        if sum(isnan(a_temp_cut(nn,:)))<4
            A(end+1,:)=a_temp_cut(nn,:);
        end
    end
else
    error('file type not valid (select 1 for .txt, 2 for .csv)')
end

%Perform truncation on data if necessary
if data_trunc(1)==1
    B=A(data_trunc(2):data_trunc(3),:);
    fname_t=sprintf('%s_trunc%i-%i',fname,data_trunc(2),data_trunc(3));
else
    B=A;
    fname_t=fname;
end

%Determine data size for file
L=size(B,1);

%Differentiate rate if necessary
if is_diff == 1
    dt=mean(B(2:L,1)-B(1:(L-1),1));
    kk=1;
    for p=1:L %for each point
        p1=p+kk; p2=p+2*kk; p3=p+3*kk; p4=p+4*kk; %define indecies of forward
            %points
        pn1=p-kk; pn2=p-2*kk; pn3=p-3*kk; pn4=p-4*kk; %define indecies of reverse
            %points
        if p1>L %wrap around points that extend beyond end of period
            p1=p1-L; p2=p2-L; p3=p3-L; p4=p4-L;
        elseif p2>L
            p2=p2-L; p3=p3-L; p4=p4-L;
        elseif p3>L
            p3=p3-L; p4=p4-L;
        elseif p4>L
            p4=p4-L;
        end
        if pn1<1 %wrap around points that extend beyond start of period
            pn1=pn1+L; pn2=pn2+L; pn3=pn3+L; pn4=pn4+L;
        elseif pn2<1
            pn2=pn2+L; pn3=pn3+L; pn4=pn4+L;
        elseif pn3<1
            pn3=pn3+L; pn4=pn4+L;
        elseif pn4<1
            pn4=pn4+L;
        end
        B(p,3)=(-3*B(p4,2)+32*B(p3,2)-168*B(p2,2)+672*B(p1,2)...
            -672*B(pn1,2)+168*B(pn2,2)-32*B(pn3,2)+3*B(pn4,2))/(840*kk*dt);
    end
end

%Sort the extracted data into transient trajectories
time_wave=B(:,1)-B(1,1)*ones(L,1);
resp_wave=B(:,2:4);

end

