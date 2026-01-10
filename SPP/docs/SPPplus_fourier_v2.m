function [] = SPPplus_fourier_v2(time_wave,resp_wave,L,omega,M,p,...
    out_set,fname)
% This Function applies the SPP Analysis by means of a fourier series. The
% results are then printed/displayed/saved by other functions as
% requested
    %Inputs: time_wave = Lx1 vector of time at each measurement point
            %resp_wave = Lx3 matrix of the strain, rate and stress data,
                %with each row representing a measuring point
            %L = number of measurement points in the extracted data
            %omega = frequency of oscilation (rad/s)
            %M = number of harmonics for stress
            %p = number of cycles
            %out_set = vector of output file parameters
            %fname = name of file from which the data originated

%=============Calculate SPP Metrics via Fourier Series=====================

format long G;

%Scale rate by frequency
if length(omega)~=1
    error('Fourier mode does not support variable frequency calculations. Use numerical mode...')
end
resp_wave(:,2) = resp_wave(:,2)/omega;

%Determine maximum number of calculatable harmonics
W = round(L/(2*p));

%Perform fourier transform of data
fft_resp = fft(resp_wave,L);
sign_fft_resp = fft_resp/L;
f_domain = linspace(0,W,W+1);
FWave = fft_resp(1:L/2,:);

%Determine indeces of relavent harmonics
k = zeros(1,W+1);
for n=1:W+1
    k(n)=p*(n-1)+1;
end

%Normalize size of fourier harmonics
sign_fft_resp_s = sign_fft_resp(:,3);
ft_amp_sign_fft_resp_s=2*abs(sign_fft_resp_s(k));
ft_amp_sign_fft_resp_s=ft_amp_sign_fft_resp_s./ft_amp_sign_fft_resp_s(2);

%separate real and imaginary components of the fourier response
FWreal = real(FWave);
FWimag = imag(FWave);

%Calculate Fourier harmonics of strain, rate, and stress
An1_n=2*FWreal(:,1)/L;
An1_n(1)=0; %becasue stress has no offset term.       %F1(1)=F1(1)/2;
Bn1_n=-2*FWimag(:,1)/L;
An1_r=2*FWreal(:,2)/L;
An1_r(1)=0; %becasue stress has no offset term.       %F1(1)=F1(1)/2;
Bn1_r=-2*FWimag(:,2)/L;
An1=2*FWreal(:,3)/L;
An1(1)=0; %becasue stress has no offset term.       %F1(1)=F1(1)/2;
Bn1=-2*FWimag(:,3)/L;

%Calculate offset factor
Delta=atan(An1_n(p+1)/Bn1_n(p+1));
if Bn1_n(p+1)<0
    Delta=Delta+pi;
end

% shift time vector appropriately
dt=2*pi/omega/L;
time_wave_new=dt*(0:(L-1))';
time_wave=time_wave+Delta/omega;

%Compensate for ofset in harmonics
J=length(An1_n);
for nn=1:(J-1)
    An_n(nn+1)=An1_n(nn+1)*cos(Delta/(p)*nn)-Bn1_n(nn+1)*sin(Delta/(p)*nn);
    Bn_n(nn+1)=Bn1_n(nn+1)*cos(Delta/(p)*nn)+An1_n(nn+1)*sin(Delta/(p)*nn);
end
J=length(An1_r);
for nn=1:(J-1)
    An_r(nn+1)=An1_r(nn+1)*cos(Delta/(p)*nn)-Bn1_r(nn+1)*sin(Delta/(p)*nn);
    Bn_r(nn+1)=Bn1_r(nn+1)*cos(Delta/(p)*nn)+An1_r(nn+1)*sin(Delta/(p)*nn);
end
J=length(An1);
for nn=1:(J-1)
    An(nn+1)=An1(nn+1)*cos(Delta/(p)*nn)-Bn1(nn+1)*sin(Delta/(p)*nn);
    Bn(nn+1)=Bn1(nn+1)*cos(Delta/(p)*nn)+An1(nn+1)*sin(Delta/(p)*nn);
end

%Set Result Vectors
Recon_Wave = [ones(L,1)*An_n(1),ones(L,1)*An_r(1),ones(L,1)*An(1)];
Recon_Wave_dot = zeros(L,3);
Recon_Wave_ddot = zeros(L,3);
Recon_Wave_dddot = zeros(L,3);

%Find fourier series for strain
for n=1:2:1
    Recon_Wave(:,1) = Recon_Wave(:,1) + An_n(p*n+1)*cos(n*omega*time_wave_new) + Bn_n(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dot(:,1) = Recon_Wave_dot(:,1) - n*omega*An_n(p*n+1)*sin(n*omega*time_wave_new) + n*omega*Bn_n(p*n+1)*cos(n*omega*time_wave_new);
    Recon_Wave_ddot(:,1) = Recon_Wave_ddot(:,1) - n^2*omega^2*An_n(p*n+1)*cos(n*omega*time_wave_new) - n^2*omega^2*Bn_n(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dddot(:,1) = Recon_Wave_dddot(:,1) + n^3*omega^3*An_n(p*n+1)*cos(n*omega*time_wave_new) - n^3*omega^3*Bn_n(p*n+1)*sin(n*omega*time_wave_new);
end

%Find fourier series for rate
for n=1:2:1
    Recon_Wave(:,2) = Recon_Wave(:,2) + An_r(p*n+1)*cos(n*omega*time_wave_new)+ Bn_r(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dot(:,2) = Recon_Wave_dot(:,2) - n*omega*An_r(p*n+1)*sin(n*omega*time_wave_new) + n*omega*Bn_r(p*n+1)*cos(n*omega*time_wave_new);
    Recon_Wave_ddot(:,2) = Recon_Wave_ddot(:,2) - n^2*omega^2*An_r(p*n+1)*cos(n*omega*time_wave_new) - n^2*omega^2*Bn_r(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dddot(:,2) = Recon_Wave_dddot(:,2) + n^3*omega^3*An_r(p*n+1)*cos(n*omega*time_wave_new) - n^3*omega^3*Bn_r(p*n+1)*sin(n*omega*time_wave_new);
end

%Find fourier series for results
for n=1:2:M
    %Stress
    Recon_Wave(:,3) = Recon_Wave(:,3) + An(p*n+1)*cos(n*omega*time_wave_new)+ Bn(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dot(:,3) = Recon_Wave_dot(:,3) - n*omega*An(p*n+1)*sin(n*omega*time_wave_new) + n*omega*Bn(p*n+1)*cos(n*omega*time_wave_new);
    Recon_Wave_ddot(:,3) = Recon_Wave_ddot(:,3) - n^2*omega^2*An(p*n+1)*cos(n*omega*time_wave_new) - n^2*omega^2*Bn(p*n+1)*sin(n*omega*time_wave_new);
    Recon_Wave_dddot(:,3) = Recon_Wave_dddot(:,3) + n^3*omega^3*An(p*n+1)*sin(n*omega*time_wave_new) - n^3*omega^3*Bn(p*n+1)*cos(n*omega*time_wave_new);
end

rd = Recon_Wave_dot;
rdd = Recon_Wave_ddot;
rddd = Recon_Wave_dddot;

rd_tn = rd/omega;
rdd_tn = rdd/omega^2;
rddd_tn = rddd/omega^3;

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
G_speed = sqrt(Gp_t_dot.^2+Gpp_t_dot.^2);

G_star_t = sqrt(Gp_t.^2+Gpp_t.^2);
tan_delta_t = Gpp_t./Gp_t;
is_Gp_t_neg = (Gp_t<0);
delta_t = atan(tan_delta_t)+pi*is_Gp_t_neg;
delta_t_dot = -1*(rd_tn(:,3).*((rddd_tn(:,3) + ...
    rd_tn(:,3)))./((rdd_tn(:,3)).^2+(rd_tn(:,3)).^2));

disp_stress = Recon_Wave(:,3)-(Gp_t.*Recon_Wave(:,1)+Gpp_t.*Recon_Wave(:,2)/omega);
eq_strain_est = Recon_Wave(:,1)-disp_stress./Gp_t;

spp_data_in = [time_wave,resp_wave];
spp_params = [omega,M,p,W,NaN,NaN]; % Length,frequency,harmonics,cycles,
    %max_harmonics,step_size,num_mode;
spp_data_out = [time_wave_new,Recon_Wave,Gp_t,Gpp_t,G_star_t,tan_delta_t,...
    delta_t,disp_stress,eq_strain_est,Gp_t_dot,Gpp_t_dot,G_speed,...
    delta_t_dot];
fsf_data_out = [Rec_Tvect,Rec_Nvect,Rec_Bvect];
ft_out = [f_domain',ft_amp_sign_fft_resp_s];

%=========================Print SPP Results================================

SPPplus_print_v2(fname,spp_params,spp_data_out,fsf_data_out,out_set(1),...
    out_set(2),'FOURIER','Data calculated via Fourier domain filtering')

%=========================Display SPP Results================================

getfigs = [1,1,1]; %specifies to produce Standard SPP figures (1st index),
    %reconstructed waveform comparison figures (2nd index), and Fourier
    %Harmonics figures (3nd index)

SPPplus_figures_v2(spp_data_in,spp_params,spp_data_out,ft_out,out_set(3),...
    'FOURIER',fname,getfigs)

end