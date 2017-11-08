clc
clear all
%% ��������    
    %����������ʱ��
    tic  
    %��֡���
    T_Slot=3.5;%d����ʱ϶����Ϊ3.5ms
    T_Frame=122.5;  %֡��Ϊ122.5ms
    %�Ŷ���ʱ��
    Normal_D_th=1000;    %����ͨ�ŵ�ʱ�ӣ���λms
    Emergency_D_th=500;     %����ͨ�ŵ�ʱ�ӣ���λms
    Normal_P_Block=0;       %������
    Emergency_P_Block=0;    
    Normal_Kesee_A=0;   
    Normal_Kesee_B=[1;1;1;1;1]; %����ͨ�����ݷ������ʵķ���ֵ
    Emergency_Kesee_B=[0.5;0.5;0.5;0.5;0.5]; %����ͨ�����ݷ������ʵķ���ֵ
    %�ڵ�
    distance=[69;36;48;23;34];%�����ͬ�Ľڵ㵽hub�ľ��룬��λΪcm
    d0=10; %�ο�����Ϊ10cm
    P0_dB=[35.2;48.4];
    n=[3.11;5.9];
    sigma_X=[6.1;5];
    LOSorNLOS=[1,2,1,1,2];%Ϊ1��ʾLOS������ʾNLOS
    P_Noise_dB=-100;%��������
    P_Out_th=0.01;%�ж�������
    P_Sensitivity=-90; %����Ϊ�˼���򵥣�����������������Ϊ�����������޹صĹ̶�ֵ
    BandWidth=1000;%��λkbps
    DataRate=[121.4;242.8;485.6;971.2]; %��ѡ�����������
    R_basic=121.4;    %�ڵ���������
    Normal_SourceRate=[16;4.8;7;32;6.4];    %����ͨ�ŵ��������ʣ���λkbps
    Emergency_SourceRate_Ave=[4;1;2;6;2];     %����ͨ�ŵ�ƽ����������,��λkbps
    %���书�����
    P_tx_min_dBm=-30;%���õ���С���书�ʣ���λΪdBm
    P_tx_max_dBm=3;%���õ�����书�ʣ���λΪdBm�� 
    %��·�ܺĺͷ����ܺ���ز���
    a=2.4;
    b=5.8;    
    %����С
    Normal_L_packet=ceil(Normal_SourceRate*T_Frame);    %���ð��Ĵ�С
    index=find(Normal_L_packet>255*8);
        %����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
        if size(index,1)>0  
              Normal_L_packet(index)=ceil(Normal_L_packet(index)/ceil(Normal_L_packet(index)/(255*8))); %����T�ڲ��������ݱ����������о��ȷְ�
        end;
    Emergency_L_packet=ceil(Emergency_SourceRate_Ave*T_Frame);    
    index=find(Emergency_L_packet>255*8);
         %����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
        if size(index,1)>0  
              Emergency_L_packet(index)=ceil(Emergency_L_packet(index)/ceil(Emergency_L_packet(index)/(255*8))); %����T�ڲ��������ݱ����������о��ȷְ�
        end;
    %BCH����
    n_BCH_PSDU=63;  %BCH�������
    k_BCH_PSDU=51;
    t_BCH_PSDU=2;
    %����������->�������
    Normal_PLR_th=0.05; %����ͨ�ŵĶ���������
    Emergency_PLR_th=0.002; %����ͨ�ŵĶ��������� 

    %����Ӳ�����µķ�������
    P_tx_min=power(10,P_tx_min_dBm/10); %��С���书�ʣ���λΪmw
    P_tx_max=power(10,P_tx_max_dBm/10); %����书�ʣ���λΪmw
    
    

