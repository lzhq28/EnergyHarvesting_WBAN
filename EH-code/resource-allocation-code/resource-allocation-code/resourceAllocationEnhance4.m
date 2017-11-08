function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance4(PNoise,deltaPL)

%% ʹ��yalmip����ggp���delayTh,KeseeB,
%˼·��
%��һ�������µ�����ʧȨ��
%�ڶ�������������ֵ��Ϊ���ֵ������������ֱ�������ѡ�񣺾�������Ĵ������Ŀ�ѡ����ɢ����ֵ�;��������С��������ɢ����ֵ
%% ���ز���
% PNoise=-94
% deltaPL=30
channelPar(PNoise,deltaPL)
load(strcat('QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load('miuThNode.mat')
posNum=3; % ����������
    tmpPL(2:2:2*N_Node,1)=NoPL';
    tmpPL(1:2:2*N_Node,1)=NoPL';    

%��һ�������ݶ�����Լ���ҵ����޵�����ֵ
for m=1:posNum    
    for nodeIndex=1:N_Node
        tmpMiuTh{m}(:,nodeIndex)=miuThNode{nodeIndex,m}(1,:)';
        tmpQoSAllNode{m}(:,nodeIndex)=BandWidth^(-1).*power(10,(tmpMiuTh{m}(:,nodeIndex)+tmpPL(2*nodeIndex)+PNoise)./10);
    end;
    
    tmpRata(1:2:2*N_Node,1)=Normal_SourceRate';
    tmpRata(2:2:2*N_Node,1)=Emergency_SourceRate_Ave';
    %QoS
    bakQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';
    bakQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    tmpQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';    
    tmpQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    threholdR=P_tx_max./tmpQoS_PiR;
        
    %�Եõ���Rֵ������ɢ��   
    iniR=power(2,floor(log2(threholdR./R_basic))).*R_basic;
    iniR(iniR<DataRate(1))=DataRate(1); %����������С����Сֵʱ��������Ϊ��С��������
    iniR(iniR>DataRate(4))=DataRate(4);
    tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot);%�����ܴ���
    %���������ʱ϶������T_Frameʱ������������ʶ����·���
    weight=zeros(size(iniR));%��ʼ��
    disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);    
    maxPL=30;
 
    
    %��QoS_PiR���г�ʼ��  
    I0=(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise)>0;%�ҵ���ʼ״̬����������С����С��������
    weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ����һ
     relaxFactor=min(1,0.08+(deltaPL./maxPL).*(1-0.08)); %���Ч��������
     tmpQoS_PiR(I0)=(relaxFactor+(1-relaxFactor).*weight(I0))./iniR(I0);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%������
%     I2=find(I0==1)
%     if ~isempty(I2) %���ǿ�
%        for ttt=1:size(I2,1)           
%            I3=find(tmpQoSAllNode{m}(:,ceil(I2(ttt)/2))<1./iniR(I2(ttt)))
%            if ~isempty(I3) 
%                avePLRSet(I3(end));
%                tmpQoS_PiR(I2(ttt))=tmpQoSAllNode{m}(I3(end),ceil(I2(ttt)/2))
%            else
%                tmpQoS_PiR(I2(ttt))=1./iniR(I2(ttt));
%            end;
%           
%        end;
%     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    weight(iniR==DataRate(4))=inf;%���Ѿ�����Ϊ���ֵ���������ʵ�weight����Ϊ�������,��ʾ�Ѿ��޷��ٽ������ϵ���
    targetR= iniR; %�м�ֵ
    deltaT=0.95;    
   
    while tmpT>deltaT*T_Frame   
        %ɸѡ��Ϊ���ֵ��
        targetR=iniR;
        I0=((iniR~=DataRate(4)));
        targetR(I0)=2*targetR(I0);
        %����Ȩ������,ѡ��Ǹ���Сֵ
        weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
        weight(iniR==DataRate(4))=inf
        %Ѱ����Сֵ
        [Y,I1]=min(weight);
        iniR(I1)=targetR(I1);
        disp(['posNum:',num2str(m),'  changeIndex:',num2str(I1)]);
        if Y==inf %��ʾ�������뷢�ͽڵ�ĵõ��������������ʶ��������������
            disp(['warning:all target data rates are larger than the max rate.'])
            %����ģ��
            break;%����
        else   
            %%%%%%%%%%%%����һ
            tmpQoS_PiR(I1)=min((relaxFactor+(1-relaxFactor).*(weight(I1))),1)./iniR(I1)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%������
%             I3=find(tmpQoSAllNode{m}(:,ceil(I1/2))<1./iniR(I1))
%             if ~isempty(I3) 
%                 avePLRSet(I3(end));
%                tmpQoS_PiR(I1)= tmpQoSAllNode{m}(I3(end),ceil(I1/2))
%             else
%                tmpQoS_PiR(I1)=1./iniR(I1);
%            end;
%            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end; 
        tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot);%�����ܴ���
        disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
    end;
    posRate{m}=iniR;     
    QoS_PiR(2*(m-1)+1,:)=tmpQoS_PiR(1:2:2*N_Node,1)';
    QoS_PiR(2*m,:)=tmpQoS_PiR(2:2:2*N_Node,1)';
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

      %% ͳ�ƽ��
      %if solution{m}.problem==0 %��������ҵ��Ż����
          posPower{m}= double(P);
          posRate{m}=double(R) ;     
          posTime{m}=double(t);         
          posMinSumEnergy(m)=double(obj);  
      %end;

%       tmpL=[];
%       tmpL(1:2:2*N_Node,1)=Normal_L_packet';
%       tmpL(2:2:2*N_Node,1)= Emergency_L_packet';
%       KeseeB{m}=repmat(avePLRth',N_Node,1).*repmat((1-avePLRth'),N_Node,1).*double(R).*double(t)./tmpL;

      posCalTime(m)=toc;   %ͳ��ÿ�μ���ʱ��
      toc    
       %��������ֵ�Ż����
         bakPosPower{m}= posPower{m};
         bakPosRate{m}= posRate{m};
         bakPosTime{m}= posTime{m};
         posPower{m}(posPower{m}>P_tx_max)=P_tx_max;%���ｫ�Ż�ֵ��û���ҵ�����ֵʱ�����ʴ������ֵ
         if sum(sum(posTime{m}))>T_Frame
            disp(['warnning in performance: sum(t)',num2str(sum(sum(posTime{m}))),'>T_Frame in pos-',num2str(i)])
         end;
 end;
 


 
 

 
 