function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance5(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT)


%%
%rateAllocationFlag Ϊ1��ʾ�������ʷ���Ĳ��ԣ��������ʾ�������������

%˼·�����ｲ�ɳ���������Ϊ����0.5
%��һ�������Ż��������ȷ�������ʣ��������������һ������Ϊ���ֵ
%�ڶ�������������ֵ��Ϊ���ֵ������������ֱ�������ѡ�񣺾�������Ĵ������Ŀ�ѡ����ɢ����ֵ�;��������С��������ɢ����ֵ

% shadowAndNumPacketPATH='shadowAndNumPacket.mat';
% load(shadowAndNumPacketPATH)
% 
% 
% %% ���ز���
%  PNoise=-94
%  deltaPL=16;
%  avePLRth=[0.1 0.075]
%  avePLRth=[0.05 0.025]
%  avePLRth=[0.025 0.01]
%  avePLRth=[0.01 0.005]
    % �����ŵ��������Ż������е�QoS���޲���
    PLRInfo=strcat('./data/PLRN',num2str(avePLRth(1)),'E',num2str(avePLRth(2)));
    ChannelParPATH =strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat');
    QoSParPATH=strcat(PLRInfo,'_QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat');
    if ((exist(ChannelParPATH)==2)&&(exist(QoSParPATH)==2)) %��������Ѿ����ڽ�ֱ�Ӽ���
        load(ChannelParPATH)
        load(QoSParPATH)
    else  %��������ڸ����ݽ�������
        channelQoSPar(PNoise,deltaPL,miuTh,avePLRth);
        load(ChannelParPATH)
        load(QoSParPATH)
    end
    disp(strcat(['avePLRth:',num2str( avePLRth),', PNoise:',num2str(PNoise),',deltaPL:',num2str(deltaPL)]))

    posNum=3; % ����������
    tmpPL(2:2:2*N_Node,1)=NoPL';
    tmpPL(1:2:2*N_Node,1)=NoPL';
 
%rateAllocationFlag=1;%Ϊ1��ʾҪ�������ʷ���
%�ɳ�����
    relaxFactor=1;
    %deltaT=0.95  %����������������ȡ���ȵ�����ʱ϶���ڳ�֡����
    if rateAllocationFlag==1
        %% ʹ�����ʷ���
        for m=1:posNum
            tmpRata(1:2:2*N_Node,1)=Normal_SourceRate';
            tmpRata(2:2:2*N_Node,1)=Emergency_SourceRate_Ave';
            bakQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';
            bakQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
            tmpQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';    
            tmpQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
            threholdR=P_tx_max./tmpQoS_PiR;
            %�Եõ���Rֵ������ɢ��
            iniR=power(2,floor(log2(threholdR./R_basic))).*R_basic;
            iniR(iniR<DataRate(1))=DataRate(1); %����������С����Сֵʱ��������Ϊ��С��������
            iniR(iniR>DataRate(4))=DataRate(4);
            tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot)%�����ܴ���
            %���������ʱ϶������T_Frameʱ������������ʶ����·���
            weight=zeros(size(iniR));%��ʼ��
            disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);    
            %��QoS_PiR���г�ʼ�� 
            I0=(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise)>0 ;%�ҵ���ʼ״̬����������С����С��������
            weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
            tmpQoS_PiR(I0)=relaxFactor*P_tx_max./iniR(I0);
            weight(iniR==DataRate(4))=inf;%���Ѿ�����Ϊ���ֵ���������ʵ�weight����Ϊ�������,��ʾ�Ѿ��޷��ٽ������ϵ���
            targetR= iniR %�м�ֵ
            while tmpT>deltaT*T_Frame   
                targetR=iniR;
                %�ҵ���Ϊ�������������е�ǰ���ʵ���
                I0=((iniR~=DataRate(4)));
                targetR(I0)=2*targetR(I0);
                %����Ȩ������,ѡ��Ǹ���Сֵ
                weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./targetR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
                weight(iniR==DataRate(4))=inf;
                %Ѱ����Сֵ
                [Y,I1]=min(weight);            
                disp(['posNum:',num2str(m),'  changeIndex:',num2str(I1)]);
                if Y==inf %��ʾ�������뷢�ͽڵ�ĵõ��������������ʶ��������������
                    disp(['warning:all target data rates are larger than the max rate.'])
                    %����ģ��
                    posRate{m}=iniR ;
                    QoS_PiR(2*(m-1)+1,:)=tmpQoS_PiR(1:2:2*N_Node,1)';
                    QoS_PiR(2*m,:)=tmpQoS_PiR(2:2:2*N_Node,1)';  
                    break;%����
                else  
                    iniR(I1)=targetR(I1);
                    tmpQoS_PiR(I1)=relaxFactor*P_tx_max./iniR(I1); 
                end
                tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot);%�����ܴ���
                disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);           
             end;
            posRate{m}=iniR;
            iniR;
            QoS_PiR(2*(m-1)+1,:)=tmpQoS_PiR(1:2:2*N_Node,1)';
            QoS_PiR(2*m,:)=tmpQoS_PiR(2:2:2*N_Node,1)';   
        end;  
    else
        %��һ��������ǰ�����������¼�ʹʹ������͹���Ҳ����PLR����Ҫ����ʱ��Ҫ�󽵵����ֵ�պ�����Ҫ���Ծ�������Ҫ��
        for m=1:posNum 
            posRate{m}(1:2*N_Node,1)=DataRate(4);%����������Ϊ���ֵ     
            bakQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';
            bakQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
            tmpQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';    
            tmpQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';       
            %��QoS_PiR���г�ʼ��  
            I0=(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./posRate{m})+10*log10(BandWidth)-tmpPL-PNoise)>0 ;%�ҵ���ʼ״̬����������С����С��������
            tmpQoS_PiR(I0)=1./DataRate(4);%��Լ������Ϊ����͹��ʺ��������������µ�ֵ
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            QoS_PiR(2*(m-1)+1,:)=tmpQoS_PiR(1:2:2*N_Node,1)';
            QoS_PiR(2*m,:)=tmpQoS_PiR(2:2:2*N_Node,1)';
        end;
    end;


    %�������
     for m=1:posNum
         % ���ñ���
         P=sdpvar(N_Node*2,1);    
         R=posRate{m};
         %assign(R,repmat( DataRate(4),N_Node*2,1))
         t=sdpvar(N_Node*2,1);
         tmpV=sdpvar(N_Node*2,1);
         sum_t=sdpvar(1);
         obj=0; %����һ���ն���ʽ
         constr=[]; %����һ���վ���
         %set constraints
         for i=1:N_Node 
                 NIndex=(i-1)*2+1;
                 EIndex=(i-1)*2+2;
                 %�ۼӷ����ʱ��
                 sum_t=sum_t+t(NIndex)+t(EIndex);
                %����Ŀ�꺯��        
                 obj=obj+((a+1)*P(NIndex)+b)*t(NIndex)+((a+1)*P(EIndex)+b)*t(EIndex);
                % obj=obj-R(NIndex)-R(EIndex);
                %% ����Լ��            
                    constr=[constr;QoS_PiR(2*(m-1)+1,i)<=P(NIndex)*R(NIndex)^(-1) ;QoS_PiR(2*(m-1)+2,i)<=P(EIndex)*R(EIndex)^(-1)];
                    constr=[constr;QoS_Rt(1,i)<=R(NIndex)*t(NIndex);QoS_Rt(2,i)<=R(EIndex)*t(EIndex)];
                    constr=[constr;QoS_iR(1,i)*R(NIndex)^(-1)+tmpV(NIndex)<=QoS_D(1,i)];
                    constr=[constr;QoS_N_RtRtiTmpV(1,i)*R(NIndex)*t(NIndex)*R(NIndex)*t(NIndex)*tmpV(NIndex)^(-1)+QoS_N_Con(1,i)<=QoS_N_Rt(1,i)*R(NIndex)*t(NIndex)];
                    constr=[constr;QoS_iR(2,i)*R(EIndex)^(-1)+tmpV(EIndex)<=QoS_D(2,i)];
                    constr=[constr;QoS_E_iRtTmpV(1,i)*R(EIndex)^(-1)*t(EIndex)^(-1)*tmpV(EIndex)^(-1)+QoS_E_RtiTmpV(1,i)*R(EIndex)*t(EIndex)*tmpV(EIndex)^(-1)+QoS_E_Con(1,i)<=QoS_E_Rt(1,i)*R(EIndex)*t(EIndex)]; 
                    constr=[constr;DataRate(1)<=R(NIndex);DataRate(1)<=R(EIndex)];
                    constr=[constr;R(NIndex)<=DataRate(4);R(EIndex)<=DataRate(4)];
                    constr=[constr;P_tx_min<=P(NIndex);P_tx_min<=P(EIndex)];
                    constr=[constr;P(NIndex)<=P_tx_max;P(EIndex)<=P_tx_max];
          end; 
          constr=[constr;sum_t<=T_Frame];  
          disp(['-----------��',num2str(m),'���Ż���ʼ-----------'])
          tic
          %solve the ggp
          solution{m} = solvesdp( constr,obj);
          if solution{m}.problem==0
              disp(['********************************************'])
              disp(['**************��ϲ���Ż��޴���**************'])
              disp(['********************************************'])
          else
              disp(['********************************************'])
              disp(['**************�ɱ����Ż����ڴ���************'])
              disp(['********************************************'])
          end;
          disp(['-----------��',num2str(m),'���Ż�����-----------'])
          posPower{m}= double(P);
          posRate{m}=double(R) ;     
          posTime{m}=double(t);         
          posMinSumEnergy(m)=double(obj);  
          posCalTime(m)=toc;   %ͳ��ÿ�μ���ʱ��
          toc    
           %��������ֵ�Ż����
             bakPosPower{m}= posPower{m};
             posPower{m}
             bakPosRate{m}= posRate{m};

             bakPosTime{m}= posTime{m};

             posPower{m}(posPower{m}>P_tx_max)=P_tx_max;%���ｫ�Ż�ֵ��û���ҵ�����ֵʱ�����ʴ������ֵ
             numNormalPacket;
            numEmergencyPacket;
            numN= posRate{m}(1:2:end).*posTime{m}(1:2:end)./Normal_L_packet';
            numE= posRate{m}(2:2:end).*posTime{m}(2:2:end)./Emergency_L_packet';
             if sum(sum(posTime{m}))>T_Frame
                disp(['warnning in performance: sum(t)',num2str(sum(sum(posTime{m}))),'>T_Frame in pos-',num2str(i)])
             end;
     end;
 


 
 

 
 