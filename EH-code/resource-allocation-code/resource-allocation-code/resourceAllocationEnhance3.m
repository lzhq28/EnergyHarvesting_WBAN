function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance3(PNoise,deltaPL)

%% ʹ��yalmip����ggp���delayTh,KeseeB,
%˼·��
%��һ���� ���ݲ���ѡ����������
%�ڶ�������������ֵ��Ϊ���ֵ������������ֱ�������ѡ�񣺾�������Ĵ������Ŀ�ѡ����ɢ����ֵ�;��������С��������ɢ����ֵ
%% ���ز���
% PNoise=-94
% deltaPL=20
channelPar(PNoise,deltaPL)
load(strcat('QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
posNum=3; % ����������

%��һ�������ݶ�����Լ���ҵ����޵�����ֵ
for m=1:posNum    
    tmpRata(1:2:2*N_Node,1)=Normal_SourceRate';
    tmpRata(2:2:2*N_Node,1)=Emergency_SourceRate_Ave';
    %QoS
    bakQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';
    bakQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    tmpQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';    
    tmpQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    tmpR1=P_tx_max./tmpQoS_PiR;
        
    %�Եõ���Rֵ������ɢ��   
    tmpR2=power(2,floor(log2(tmpR1./R_basic))).*R_basic;
    tmpR2(tmpR2<DataRate(1))=DataRate(1); %����������С����Сֵʱ��������Ϊ��С��������
    tmpR2(tmpR2>DataRate(4))=DataRate(4);
    tmpT=sum(ceil(tmpRata.*T_Frame./tmpR2./T_Slot).*T_Slot);%�����ܴ���
    %���������ʱ϶������T_Frameʱ������������ʶ����·���
    weight=zeros(size(tmpR2));%��ʼ��
    disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
    
    
    weight=tmpRata.*T_Frame.*((1-tmpR2./tmpR1).*tmpQoS_PiR)./tmpR2;
    weight(tmpR2==DataRate(4))=-inf;%���Ѿ�����Ϊ���ֵ���������ʵ�weight����Ϊ�������,��ʾ�Ѿ��޷��ٽ������ϵ���
    I0=(tmpR2==DataRate(1));%�ҵ���һ��Ϊ��������Ϊ��Сֵ����Щ�������ʶ�Ӧ��Ȩ��Ӧ�ü�����Ȩ��ֵ��
    weight(I0)=1/20.*weight(I0);%��Ȩ��ֵ����Ϊԭ����ֵ��factor���������Ǿ���ֵ
    deltaQ=0.3;
    tmpQoS_PiR(I0)=deltaQ*1./tmpR2(I0);
    deltaT=0.98;    
    while tmpT>deltaT*T_Frame        
        deltaQ=0.5;
        %ѡ��Ȩ��������������ʵ���Ϊԭ��������
        if sum(weight~=-inf)~=0 %���������������û�������ֵ�����            
            if sum(weight>0)~=0 %������п���δ�ϵ����Ľڵ�
                [Y I]=sort(weight,'descend');%�ҵ����weight�ĵ�
                if tmpR2(I(1))~=DataRate(4) %�ٴ��ж��Ƿ������ֵ
                    tmpR2(I(1))=tmpR2(I(1))*2;
                    %deltaQ=(max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))-min(1/tmpR2(I(1)),bakQoS_PiR(I(1))))./max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))
                    tmpQoS_PiR(I(1))=min(tmpQoS_PiR(I(1)),deltaQ*1/tmpR2(I(1)));%������Խ�����ƣ���PLRԼ��ֵ����Ϊԭ��Լ��ֵ�������������������Լ��ֵ
                    disp(['posNum:',num2str(m),'  changeIndex:',num2str(I(1))]);
                else 
                    tmpQoS_PiR(I(1))=deltaQ*1./tmpR2(I(1));                                                                                                    
                end;
            else %weight ��Ϊ����ʱ����������Щ��Ϊ0��ֵ�����սڵ�ľ���ֵ
                I0=(weight~=-inf);
                weight(I0)=abs(weight(I0));
                [Y I]=sort(weight,'descend');
                if tmpR2(I(1))~=DataRate(4) %�ٴ��ж��Ƿ������ֵ
                    tmpR2(I(1))=tmpR2(I(1))*2;
                    %deltaQ=(max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))-min(1/tmpR2(I(1)),bakQoS_PiR(I(1))))./max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))
                    tmpQoS_PiR(I(1))=min(tmpQoS_PiR(I(1)),deltaQ*1/tmpR2(I(1)));%������Խ�����ƣ���PLRԼ��ֵ����Ϊԭ��Լ��ֵ�������������������Լ��ֵ
                    disp(['posNum:',num2str(m),'  changeIndex:',num2str(I(1))]);
                else 
                    tmpQoS_PiR(I(1))=deltaQ*1./tmpR2(I(1));                                                                                                    
                end;
                
            end;
            %�����ǽ��������������Ĳ��죬���Ҳ����ǽڵ�����ȼ�         

        else %��ȫ�������ʶ�����Ϊ���ֵʱ��1����Լ������Ϊ��2������ѭ��
            disp(['posNum:',num2str(m),' all rates are max']);
            break; %����ѭ��
        end;
        tmpT=sum(ceil(tmpRata.*T_Frame./tmpR2./T_Slot).*T_Slot);%�����ܴ���
        disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
        weight=tmpRata.*T_Frame.*((1-tmpR2./tmpR1).*tmpQoS_PiR)./tmpR2;
        weight(tmpR2==DataRate(4))=-inf;%���Ѿ�����Ϊ���ֵ���������ʵ�weight����Ϊ�������,��ʾ�Ѿ��޷��ٽ������ϵ���
    end;
    posRate{m}=tmpR2;
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
          disp(['****************************************'])
          disp(['**************��ϲ���Ż��޴���**************'])
          disp(['****************************************'])
      else
          disp(['****************************************'])
          disp(['**************�ɱ����Ż����ڴ���**************'])
          disp(['****************************************'])

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
 


 
 

 
 