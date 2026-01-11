function [] = SPPplus_figures_v2(spp_data_in,spp_params,spp_data_out,...
    ft_out,pfstate,analtype,fname,f_vect)
% This function produces figures using the SPP analysis; if specified by
% the user, the figures can also be saved to .jpg files
    %Inputs: spp_data_in = Lx4 matrix of the data input to the analysis,
                %with each row representing a measuring point. The columns
                %are: 1 - time [s]
                % 2 - strain [-]
                % 3 - rate [1/s]
                % 4 - stress [Pa]
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
            %ft_out = Lx2 vector containing the fourier domain filtering
                %results. If numerical differentiation was used, this is
                %NaN. The columns are:
                % 1 - domain
                % 2 - normalized harmonics
            %pf_state = binary value determining whether to save figures
                %as .jpg files
            %analtype = analysis method used (as a string)
            %fname = name of file from which the data originated
            %f_vect = vector that specifies which figures to create

%Produce figure title
fig_name=sprintf('SPPplus_%s_v1 by Rogers group@UIUC',analtype);

%Base SPP metrics figure
if f_vect(1) == 1
    figure('Name',fig_name)
    %Stress-Strain plot
    subplot(2,2,1)
    plot(spp_data_in(:,2),spp_data_in(:,4),'k--')
    hold on
    plot(spp_data_out(:,2),spp_data_out(:,4),'r--o','MarkerSize',1)
    hold on
    xlim1 = get(gca,'xlim');  %Get x range 
    ylim2 = get(gca,'ylim');  %Get y range 
    maxX=max(abs(xlim1));
    maxY=max(abs(ylim2));
    axis([-1.2*maxX 1.2*maxX -1.2*maxY 1.2*maxY]);
    hold on
    plot([-1.2*maxX 1.2*maxX],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-1.2*maxY 1.2*maxY],'k:','LineWidth',0.1)
    xlabel('Strain [-]')
    ylabel('Stress [Pa]')
    title('Stress-strain')
    legend('Raw stress output', 'Reconstructed stress','Location','northeast')
    hold off
    
    %Stress-Rate plot
    subplot(2,2,3)
    plot(spp_data_in(:,3),spp_data_in(:,4),'k--')
    hold on
    plot(spp_data_out(:,3),spp_data_out(:,4),'r--o','MarkerSize',1)
    xlim1 = get(gca,'xlim');  %Get x range 
    ylim2 = get(gca,'ylim');  %Get y range 
    maxX=max(abs(xlim1));
    maxY=max(abs(ylim2));
    axis([-1.2*maxX 1.2*maxX -1.2*maxY 1.2*maxY]);
    hold on
    plot([-1.2*maxX 1.2*maxX],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-1.2*maxY 1.2*maxY],'k:','LineWidth',0.1)
    xlabel('Rate [1/s]')
    ylabel('Stress [Pa]')
    title('Stress-rate')
    hold off
    
    %Cole-Cole plot
    subplot(2,2,2)
    plot(spp_data_out(:,5),spp_data_out(:,6),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,5));
    minX=min(spp_data_out(:,5));
    maxY=max(spp_data_out(:,6));
    minY=min(spp_data_out(:,6));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('G''_{t} [Pa]')
    ylabel('G"_{t} [Pa]')
    title('Cole-Cole plot')
    hold off
    
    %VGP plot
    subplot(2,2,4)
    plot(spp_data_out(:,7),spp_data_out(:,9),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,7));
    minX=min(spp_data_out(:,7));
    maxY=max(spp_data_out(:,9));
    minY=min(spp_data_out(:,9));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('G*_t [Pa]')
    ylabel('delta_t [rad]')
    title('VGP plot')
    
    %Save figure if requested
    if pfstate == 1
        fignum = gcf;
        fignum.Position = [0,0,1920,1080];
        image1_name = sprintf('%s_SPP_%s_PLOT.jpg',fname,analtype);
        print(image1_name,'-djpeg')
    end
end

%SPP metrics speed figure
if f_vect(1) == 1
    figure('Name',fig_name)    
    %Cole-Cole plot
    subplot(2,2,2)
    plot(spp_data_out(:,5),spp_data_out(:,6),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,5));
    minX=min(spp_data_out(:,5));
    maxY=max(spp_data_out(:,6));
    minY=min(spp_data_out(:,6));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('G''_{t} [Pa]')
    ylabel('G"_{t} [Pa]')
    title('Cole-Cole plot')
    hold off
    
    %dG"_{t}/dt-dG'_{t}/dt plot
    subplot(2,2,3)
    plot(spp_data_out(:,12),spp_data_out(:,13),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,12));
    minX=min(spp_data_out(:,12));
    maxY=max(spp_data_out(:,13));
    minY=min(spp_data_out(:,13));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('dG''_{t}/dt [Pa/s]')
    ylabel('dG"_{t}/dt [Pa/s]')
    title('dG"_{t}/dt-dG''_{t}/dt')
    
    %Speed-G'_{t} plot
    subplot(2,2,4)
    plot(spp_data_out(:,5),spp_data_out(:,14),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,5));
    minX=min(spp_data_out(:,5));
    maxY=max(spp_data_out(:,14));
    minY=min(spp_data_out(:,14));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('G''_{t} [pa]')
    ylabel('Speed [Pa/s]')
    title('Speed-G''_{t}')
    
    %Speed-G"_{t} plot
    subplot(2,2,1)
    plot(spp_data_out(:,14),spp_data_out(:,6),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,14));
    minX=min(spp_data_out(:,14));
    maxY=max(spp_data_out(:,6));
    minY=min(spp_data_out(:,6));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    ylabel('G"_{t} [Pa]')
    xlabel('Speed [Pa/s]')
    title('Speed-G"_{t}')
    
    %Save figure if requested
    if pfstate == 1
        fignum = gcf;
        fignum.Position = [0,0,1920,1080];
        image1_name = sprintf('%s_SPP_%s_SPEED.jpg',fname,analtype);
        print(image1_name,'-djpeg')
    end
end

%SPP metrics additional plots
if f_vect(1) == 1
    figure('Name',fig_name)    
    %delta_t v strain plot
    subplot(2,2,1)
    plot(spp_data_out(:,2),spp_data_out(:,9),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,2));
    minX=min(spp_data_out(:,2));
    maxY=max(spp_data_out(:,9));
    minY=min(spp_data_out(:,9));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('strain [-]')
    ylabel('delta_t [rad]')
    title('delta_t-strain')
    hold off
    
    %PAV v strain plot
    subplot(2,2,3)
    plot(spp_data_out(:,2),spp_data_out(:,15),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,2));
    minX=min(spp_data_out(:,2));
    maxY=max(spp_data_out(:,15));
    minY=min(spp_data_out(:,15));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('strain [-]')
    ylabel('PAV [] (time-normalized)')
    title('PAV-strain')
    hold off
    
    %displacement stress plot
    subplot(2,2,2)
    plot(spp_data_out(:,2),spp_data_out(:,10),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,2));
    minX=min(spp_data_out(:,2));
    maxY=max(spp_data_out(:,10));
    minY=min(spp_data_out(:,10));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('strain [-]')
    ylabel('displacement stress [Pa]')
    title('displacement stress-strain')
    hold off
    
    %estimated eq strain plot
    subplot(2,2,4)
    plot(spp_data_out(:,5),spp_data_out(:,11),'r','LineWidth',1.5)
    maxX=max(spp_data_out(:,5));
    minX=min(spp_data_out(:,5));
    maxY=max(spp_data_out(:,11));
    minY=min(spp_data_out(:,11));
    diffX=maxX-minX;
    if diffX==0
        diffX=0.01;
    end
    diffY=maxY-minY;
    if diffY==0
        diffY=0.01;
    end
    axis([(minX-0.2*diffX) (maxX+0.2*diffX) (minY-0.2*diffY) (maxY+0.2*diffY)]);
    hold on
    plot([-10^10 10^10],[0 0],'k:','LineWidth',0.1)
    hold on
    plot([0 0],[-10^10 10^10],'k:','LineWidth',0.1)
    hold on
    plot([-10^10 10^10],[-10^10 10^10],'k:','LineWidth',0.1)
    xlabel('G''_{t} [Pa]')
    ylabel('est. eq. strain [-]')
    title('est. eq. strain-tan(delta)')
    hold off
    
    %Save figure if requested
    if pfstate == 1
        fignum = gcf;
        fignum.Position = [0,0,1920,1080];
        image1_name = sprintf('%s_SPP_%s_MORE.jpg',fname,analtype);
        print(image1_name,'-djpeg')
    end
end

%Waveform Comparison
if f_vect(2) == 1
    figure('Name',fig_name)
    %Strain-Time plot
    subplot(3,1,1)
    plot(spp_data_out(:,1),spp_data_out(:,2),'r','LineWidth',2)
    hold on
    plot(spp_data_in(:,1),spp_data_in(:,2),'k:','LineWidth',2)
    xlabel('Time [s]')
    ylabel('Strain [-]')
    title('Strain-time')
    
    %Rate-Time plot
    subplot(3,1,2)
    plot(spp_data_out(:,1),spp_data_out(:,3),'r','LineWidth',2)
    hold on
    plot(spp_data_in(:,1),spp_data_in(:,3),'k:','LineWidth',2)
    xlabel('Time [s]')
    ylabel('Rate [1/s]')
    title('Rate-time')
    
    %Stress-Time plot
    subplot(3,1,3)
    plot(spp_data_out(:,1),spp_data_out(:,4),'r','LineWidth',2)
    hold on
    plot(spp_data_in(:,1),spp_data_in(:,4),'k:','LineWidth',2)
    xlabel('Time [s]')
    ylabel('Stress [Pa]')
    title('Stress-time')
    
    %Save figure if requested
    if pfstate == 1
        fignum = gcf;
        fignum.Position = [0,0,1920,1080];
        image2_name = sprintf('%s_SPP_%s_WAVECHECK.jpg',fname,analtype);
        print(image2_name,'-djpeg')
    end
end

%FT-spectra for stress
if f_vect(3) == 1
    figure('Name',fig_name)
    %Stress-Time plot
    subplot(2,1,1)
    plot(spp_data_out(:,1),spp_data_out(:,4),'r','LineWidth',2)
    hold on
    plot(spp_data_in(:,1),spp_data_in(:,4),'k:','LineWidth',2)
    xlabel('Time [s]')
    ylabel('Stress [Pa]')
    title('Stress-time')
    
    %Fourier Harmonic Magnitudes plot
    subplot(2,1,2)
    stem(ft_out(:,1),ft_out(:,2),'b.','LineWidth',0.5)
    hold on
    plot([spp_params(2) spp_params(2)],[10^-10 0.7],'r-','LineWidth',2)
    set(gca,'yscale','log');
    xlim([0 spp_params(4)+2]);
    ylabel('I_{n}/I_{1} [-]')
    xlabel('Number of harmonics [-]')
    title('Fourier spectrum','fontweight','bold')
    
    %Save figure if requested
    if pfstate == 1
        fignum = gcf;
        fignum.Position = [0,0,1920,1080];
        image2_name = sprintf('%s_SPP_%s_HARMONICS.jpg',fname,analtype);
        print(image2_name,'-djpeg')
    end
end

end

