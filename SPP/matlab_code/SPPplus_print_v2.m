function [] = SPPplus_print_v2(fname,spp_params,spp_data_out,...
    fsf_data_out,otype,ostate,analtype,note_A)
% This function prints data from the SPP analysis to one or more text files,
% as specified by the user
    %Inputs: fname = name of file from which the data originated
            %spp_params = 1x6 vector containing input parameters for the
                %spp analysis (frequency,#harmonics used,#cycles,maximum
                %#harmonics,step size,num mode). All non-applicable
                %values are NaN
            %spp_data_out = Lx15 matrix containing all primary results from
                %the SPP analysis. The columns are:
                % 1 - time [s]
                % 2 - strain [-]
                % 3 - rate [1/s]
                % 4 - stress [Pa]
                % 5 - G'_t [Pa]
                % 6 - G''_t [Pa]
                % 7 - |G*_t| [Pa]
                % 8 - tan(delta_t) []
                % 9 - delta_t [rad]
                % 10 - displacement stress [Pa]
                % 11 - estimated equilibrium strain [-]
                    %(valid for G'_t>>G''_t)
                % 12 - derivative of G'_t [Pa/s]
                % 13 - derivative of G''_t [Pa/s]
                % 14 - speed of G*_t [Pa/s]
                % 15 - Normalized phase angle velocity []
                    %(assumes that strain is sinusoidal)
            %fsf_data_out = Lx9 matrix containing the components of the
                %frenet-serret frame vectors. The columns are:
                % 1,2,3 - T_x,y,z
                % 4,5,6 - N_x,y,z
                % 7,8,9 - B_x,y,z
            %otype = type of file being written
                %1 -> .txt file 
                %2 -> .mat file
            %ostate = binary value determining whether to print the fsf
                %data file
            %analtype = analysis method used (as a string)
            %note_A = text that varies based on method used (as a string)
            
params_info=ones(1,6)-isnan(spp_params);
            
if otype==1
    %Standard SPP data file
    f_name=sprintf('%s_SPP_%s.txt',fname,analtype);
    txt0=sprintf('%s\r\n',note_A);
    dlmwrite(f_name,txt0,'');
    if params_info(1)==1
        txt1=sprintf('%s\t%.7f\r\n','Frequency:',spp_params(1));
        dlmwrite(f_name,txt1,'-append','delimiter', '');
    end
    if params_info(2)==1
        txt2=sprintf('%s\t%i\r\n','Number of harmonics used:',spp_params(2));
        dlmwrite(f_name,txt2,'-append','delimiter', '');
    end
    if params_info(3)==1
        txt3=sprintf('%s\t%i\r\n','Number of cycles in input:',spp_params(3));
        dlmwrite(f_name,txt3,'-append','delimiter', '');
    end
    if params_info(5)==1
        txt5=sprintf('%s\t%i\r\n','Step size for numerical diff.:',spp_params(5));
        dlmwrite(f_name,txt5,'-append','delimiter', '');
    end
    if params_info(6)==1
        if spp_params(6)==1
            txt6=sprintf('%s\r\n','Standard differentiation');
        elseif spp_params(6)==2
            txt6=sprintf('%s\r\n','Looped differentiation');
        else
            error('differentiation type not valid')
        end
        dlmwrite(f_name,txt6,'-append','delimiter', '');
    end
    hdr1={'Time','Strain','Rate','Stress','G''_t','G"_t','|G*_t|',...
        'tan(delta_t)','delta_t','displacement stress',...
        'est. elastic stress','dG''_{t}/dt','dG"_{t}/dt','Speed',...
        'norm. PAV'}; % First Header
    hdr2={'[s]','[-]','[1/s]','[Pa]','[Pa]','[Pa]','[Pa]','[]','[rad]',...
        '[Pa]','[Pa]','[Pa/s]','[Pa/s]','[Pa/s]','[]'}; % Second header
    txt_hdr=sprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n',...
        hdr1{:},hdr2{:});
    dlmwrite(f_name,txt_hdr,'-append','delimiter', '');
    %Print SPP data
    dlmwrite(f_name,[spp_data_out(:,1),spp_data_out(:,2),spp_data_out(:,3),...
        spp_data_out(:,4),spp_data_out(:,5),spp_data_out(:,6),...
        spp_data_out(:,7),spp_data_out(:,8),spp_data_out(:,9),...
        spp_data_out(:,10),spp_data_out(:,11),spp_data_out(:,12),...
        spp_data_out(:,13),spp_data_out(:,14),spp_data_out(:,15)],...
        '-append','delimiter', '\t','precision','%.7f','newline','pc');
    %Extended SPP data file(s)
    if ostate == 1
        %Output file name
        f_name1=sprintf('%s_SPP_%s_FSFRAME.txt',fname,analtype);
        txt0=sprintf('%s\r\n',note_A);
        dlmwrite(f_name1,txt0,'');
        if params_info(1)==1
            txt1=sprintf('%s\t%.7f\r\n','Frequency:',spp_params(1));
            dlmwrite(f_name1,txt1,'-append','delimiter', '');
        end
        if params_info(2)==1
            txt2=sprintf('%s\t%i\r\n','Number of harmonics used:',spp_params(2));
            dlmwrite(f_name1,txt2,'-append','delimiter', '');
        end
        if params_info(3)==1
            txt3=sprintf('%s\t%i\r\n','Number of cycles in input:',spp_params(3));
            dlmwrite(f_name1,txt3,'-append','delimiter', '');
        end
        if params_info(5)==1
            txt5=sprintf('%s\t%i\r\n','Step size for numerical diff.:',spp_params(5));
            dlmwrite(f_name1,txt5,'-append','delimiter', '');
        end
        if params_info(6)==1
            if spp_params(6)==1
                txt6=sprintf('%s\r\n','Standard differentiation');
            elseif spp_params(6)==2
                txt6=sprintf('%s\r\n','Looped differentiation');
            else
                error('differentiation type not valid')
            end
            dlmwrite(f_name1,txt6,'-append','delimiter', '');
        end
        %Set up title rows
        hdr1={'Tangent(x)','Tangent(y)','Tangent(z)','Normal(x)','Normal(y)',...\
            'Normal(z)','Binormal(x)','Binormal(y)','Binormal(z)'}; % First Header
        hdr2={'[-]','[1/s]','[Pa]','[-]','[1/s]','[Pa]','[-]','[1/s]','[Pa]'}; % Second header
        %Print title rows
        txt_hdr=sprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\r\n',...
            hdr1{:},hdr2{:});
        dlmwrite(f_name1,txt_hdr,'-append','delimiter', '');
        %Print SPP data
        dlmwrite(f_name1,[fsf_data_out(:,1),fsf_data_out(:,2),...
            fsf_data_out(:,3),fsf_data_out(:,4),fsf_data_out(:,5),...
            fsf_data_out(:,6),fsf_data_out(:,7),fsf_data_out(:,8),...
            fsf_data_out(:,9)],'-append','delimiter', '\t','precision',...
            '%.7f','newline','pc');
    end
elseif otype==2
    %Standard SPP data file
    f_name=sprintf('%s_SPP_%s.mat',fname,analtype);
    info=[];
    info.data_calc={note_A};
	if params_info(1)==1
        info.frequency=spp_params(1);
    end
    if params_info(2)==1
        info.number_of_harmonics=spp_params(2);
    end
    if params_info(2)==1
        info.number_of_cycles=spp_params(3);
    end
    if params_info(5)==1
        info.diff_step_size=spp_params(5);
    end
    if params_info(6)==1
        if spp_params(6)==1
            info.diff_type={'Standard differentiation'};
        elseif spp_params(6)==2
            info.diff_type={'Looped differentiation'};
        else
            error('differentiation type not valid')
        end
    end
    headers={'Time','Strain','Rate','Stress','G''_t','G"_t','|G*_t|',...
        'tan(delta_t)','delta_t','displacement stress',...
        'est. elastic stress','dG''_{t}/dt','dG"_{t}/dt','Speed',...
        'norm. PAV';'[s]','[-]','[1/s]','[Pa]','[Pa]','[Pa]','[Pa]','[]',...
        '[rad]','[Pa]','[Pa]','[Pa/s]','[Pa/s]','[Pa/s]','[]'};
    out_spp=[];
    out_spp.info=info;
    out_spp.headers=headers;
    out_spp.data=spp_data_out;
    save(f_name,'out_spp')
    %Extended SPP data file(s)
    if ostate == 1
        f_name1=sprintf('%s_SPP_%s_FSFRAME.mat',fname,analtype);
        headers1={'Tangent(x)','Tangent(y)','Tangent(z)','Normal(x)',...
            'Normal(y)','Normal(z)','Binormal(x)','Binormal(y)',...
            'Binormal(z)';'[-]','[1/s]','[Pa]','[-]','[1/s]','[Pa]','[-]',...
            '[1/s]','[Pa]'};
        out_fsf=[];
        out_fsf.info=info;
        out_fsf.headers=headers1;
        out_fsf.data=fsf_data_out;
        save(f_name1,'out_fsf')
    end
else
    error('file type not valid (select 1 for .txt, 2 for .mat)')
end

end

