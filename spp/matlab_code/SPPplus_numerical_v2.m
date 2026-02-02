function [] = SPPplus_numerical_v2(time_wave,resp_wave,L,omega,k,num_mode,...
    out_set,fname)
% This Function applies the SPP Analysis by means of a numerical
% differentiation. The results are then printed/displayed/saved by other
% functions as requested
    %Inputs: time_wave = Lx1 vector of time at each measurement point
            %resp_wave = Lx3 matrix of the strain, rate and stress data,
                %with each row representing a measuring point
            %L = number of measurement points in the extracted data
            %k = step size for numerical differentiation
            %num_mode = method# to use for numerical differentiation,
                %specified by the user
            %out_set = vector of output file parameters
            %fname = name of file from which the data originated

%Calculate the frequency of the response
% omega = max(abs(resp_wave(:,2)))/max(abs(resp_wave(:,1)));

if length(omega) == 1
    resp_wave(:,2) = resp_wave(:,2)/omega;
elseif length(omega) == L
    resp_wave(:,2) = resp_wave(:,2)./omega;
else
    error('Frequecy must either have a single value or be same length as data')
end


%Calculate the average timestep size
dt = sum(time_wave(2:L)-time_wave(1:(L-1)))/(L-1);

%Initialize result vectors
rd = zeros(L,3);
rdd = zeros(L,3);
rddd = zeros(L,3);

%Perform Numerical differentiation
for p=1:L
    if num_mode == 1
        %use "standard" differentiation on the response data (does not make
            %assumtions abot the form of the data, uses forward/backward
            %difference at ends and centered derivative elsewhere)
        if p<=3*k
            rd(p,:) = (-resp_wave(p+2*k,:)+4*resp_wave(p+k,:)-3*resp_wave(p,:))/(2*k*dt);
            rdd(p,:) = (-resp_wave(p+3*k,:)+4*resp_wave(p+2*k,:)-5*resp_wave(p+k,:)+2*resp_wave(p,:))/((k*dt)^2);
            rddd(p,:) = (-3*resp_wave(p+4*k,:)+14*resp_wave(p+3*k,:)-24*resp_wave(p+2*k,:)+18*resp_wave(p+k,:)-5*resp_wave(p,:))/(2*(k*dt)^3);
        elseif p>=(L-3*k)
            rd(p,:) = (resp_wave(p-2*k,:)-4*resp_wave(p-k,:)+3*resp_wave(p,:))/(2*k*dt);
            rdd(p,:) = (-resp_wave(p-3*k,:)+4*resp_wave(p-2*k,:)-5*resp_wave(p-k,:)+2*resp_wave(p,:))/((k*dt)^2);
            rddd(p,:) = (3*resp_wave(p-4*k,:)-14*resp_wave(p-3*k,:)+24*resp_wave(p-2*k,:)-18*resp_wave(p-k,:)+5*resp_wave(p,:))/(2*(k*dt)^3);
        else
            rd(p,:) = (-resp_wave(p+2*k,:)+8*resp_wave(p+k,:)-8*resp_wave(p-k,:)+resp_wave(p-2*k,:))/(12*k*dt);
            rdd(p,:) = (-resp_wave(p+2*k,:)+16*resp_wave(p+k,:)-30*resp_wave(p,:)+16*resp_wave(p-k,:)-resp_wave(p-2*k,:))/(12*(k*dt)^2);
            rddd(p,:) = (-resp_wave(p+3*k,:)+8*resp_wave(p+2*k,:)-13*resp_wave(p+k,:)+13*resp_wave(p-k,:)-8*resp_wave(p-2*k,:)+resp_wave(p-3*k,:))/(8*(k*dt)^3);
        end
    elseif num_mode == 2
        % use "looped" differentiation on the response data (assumes steady
            %state oscilatory, uses centered difference everywhere by
            %connecting the data in a loop)
        p3 = p+3*k;
        p2 = p+2*k;
        p1 = p+k;
        pn1 = p-k;
        pn2 = p-2*k;
        pn3 = p-3*k;
        if p3>L
            p3 = p3-L;
        end
        if p2>L
            p2 = p2-L;
        end
        if p1>L
            p1 = p1-L;
        end
        if pn1<1
            pn1 = pn1+L;
        end
        if pn2<1
            pn2 = pn2+L;
        end
        if pn3<1
            pn3 = pn3+L;
        end
        rd(p,:) = (-resp_wave(p2,:)+8*resp_wave(p1,:)-8*resp_wave(pn1,:)+resp_wave(pn2,:))/(12*k*dt);
        rdd(p,:) = (-resp_wave(p2,:)+16*resp_wave(p1,:)-30*resp_wave(p,:)+16*resp_wave(pn1,:)-resp_wave(pn2,:))/(12*(k*dt)^2);
        rddd(p,:) = (-resp_wave(p3,:)+8*resp_wave(p2,:)-13*resp_wave(p1,:)+13*resp_wave(pn1,:)-8*resp_wave(pn2,:)+resp_wave(pn3,:))/(8*(k*dt)^3);
    else
        error('differentiation type not valid')
    end
end

rd_x_rdd = [rd(:,2).*rdd(:,3)-rd(:,3).*rdd(:,2),...
    rd(:,3).*rdd(:,1)-rd(:,1).*rdd(:,3),...
    rd(:,1).*rdd(:,2)-rd(:,2).*rdd(:,1)];
rd_x_rd_x_rdd = [rd(:,2).*rd_x_rdd(:,3)-rd(:,3).*rd_x_rdd(:,2),...
    rd(:,3).*rd_x_rdd(:,1)-rd(:,1).*rd_x_rdd(:,3),...
    rd(:,1).*rd_x_rdd(:,2)-rd(:,2).*rd_x_rdd(:,1)];
mag_rd = sqrt(rd(:,1).^2+rd(:,2).^2+rd(:,3).^2);
Rec_Tvect = rd;
mag_rd_x_rdd = sqrt(rd_x_rdd(:,1).^2+rd_x_rdd(:,2).^2+rd_x_rdd(:,3).^2);
Rec_Nvect = -rd_x_rd_x_rdd./(mag_rd.*mag_rd_x_rdd);
Rec_Bvect = rd_x_rdd./mag_rd_x_rdd;
Gp_t = -rd_x_rdd(:,1)./rd_x_rdd(:,3);
Gpp_t = -rd_x_rdd(:,2)./rd_x_rdd(:,3);
Gp_t_dot = -rd(:,2).*(rddd(:,1).*rd_x_rdd(:,1)+rddd(:,2).*rd_x_rdd(:,2)+rddd(:,3).*rd_x_rdd(:,3))./(rd_x_rdd(:,3)).^2;
Gpp_t_dot = rd(:,1).*(rddd(:,1).*rd_x_rdd(:,1)+rddd(:,2).*rd_x_rdd(:,2)+rddd(:,3).*rd_x_rdd(:,3))./(rd_x_rdd(:,3)).^2;
G_speed = sqrt((Gp_t_dot).^2+(Gpp_t_dot).^2);

if length(omega) == 1
    rd_tn = rd/omega;
    rdd_tn = rdd/omega^2;
    rddd_tn = rddd/omega^3;
else
    rd_tn = rd./omega;
    rdd_tn = rdd./omega.^2;
    rddd_tn = rddd./omega.^3;
end

G_star_t = sqrt(Gp_t.^2+Gpp_t.^2);
tan_delta_t = Gpp_t./Gp_t;
is_Gp_t_neg = (Gp_t<0);
delta_t = atan(tan_delta_t)+pi*is_Gp_t_neg;
delta_t_dot = -1*(rd_tn(:,3).*((rddd_tn(:,3) + ...
    rd_tn(:,3)))./((rdd_tn(:,3)).^2+(rd_tn(:,3)).^2));

if length(omega) == 1
    disp_stress = resp_wave(:,3)-(Gp_t.*resp_wave(:,1)+Gpp_t.*resp_wave(:,2)/omega);
else
    disp_stress = resp_wave(:,3)-(Gp_t.*resp_wave(:,1)+Gpp_t.*resp_wave(:,2)./omega);
end
eq_strain_est = resp_wave(:,1)-disp_stress./Gp_t;

spp_data_in = [time_wave,resp_wave];
spp_params = [mean(omega),NaN,NaN,NaN,k,num_mode]; % Length,frequency,harmonics,cycles,
    %max_harmonics,step_size,num_mode;
spp_data_out = [time_wave,resp_wave,Gp_t,Gpp_t,G_star_t,tan_delta_t,...
    delta_t,disp_stress,eq_strain_est,Gp_t_dot,Gpp_t_dot,G_speed,...
    delta_t_dot];
fsf_data_out = [Rec_Tvect,Rec_Nvect,Rec_Bvect];

%=========================Print SPP Results================================

SPPplus_print_v2(fname,spp_params,spp_data_out,fsf_data_out,out_set(1),...
    out_set(2),'NUMERICAL','Data calculated via numerical differentiation')

%=========================Display SPP Results==============================

getfigs = [1,0,0];%specifies to produce only Standard SPP figures
    %(1st index)
            
SPPplus_figures_v2(spp_data_in,spp_params,spp_data_out,NaN,out_set(3),...
    'NUMERICAL',fname,getfigs)

end

