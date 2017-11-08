function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance()

%% ʹ��yalmip����ggp���delayTh,KeseeB,
%˼·��
%��һ����������ֵ����Ϊ���ֵ��Ȼ��õ���Ӧ���Ż�����ֵ
%�ڶ�������������ֵ��Ϊ���ֵ������������ֱ�������ѡ�񣺾�������Ĵ������Ŀ�ѡ����ɢ����ֵ�;��������С��������ɢ����ֵ
%% ���ز���
channelPar
load('QoS.mat')
load('channel.mat')

posNum=3; % ����������


%��һ����������ֵ����Ϊ���ֵ��Ȼ��õ���Ӧ���Ż�����ֵ
%�������
 for m=1:posNum
     % ���ñ���
     %P=sdpvar(N_Node*2,1);
     P=ones(N_Node*2,1);
     R=sdpvar(N_Node*2,1);
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
%                constr=[constr;QoS_iR(1,i)*R(NIndex)^(-1)+tmpV(NIndex)<=QoS_D(1,i)];
%                constr=[constr;QoS_N_RtRtiTmpV(1,i)*R(NIndex)*t(NIndex)*R(NIndex)*t(NIndex)*tmpV(NIndex)^(-1)+QoS_N_Con(1,i)<=QoS_N_Rt(1,i)*R(NIndex)*t(NIndex)];
%                 constr=[constr;QoS_iR(2,i)*R(EIndex)^(-1)+tmpV(EIndex)<=QoS_D(2,i)];
%                 constr=[constr;QoS_E_iRtTmpV(1,i)*R(EIndex)^(-1)*t(EIndex)^(-1)*tmpV(EIndex)^(-1)+QoS_E_RtiTmpV(1,i)*R(EIndex)*t(EIndex)*tmpV(EIndex)^(-1)+QoS_E_Con(1,i)<=QoS_E_Rt(1,i)*R(EIndex)*t(EIndex)]; 
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
      disp(['-----------��',num2str(m),'���Ż�����-----------'])

      %% ͳ�ƽ��
      posPower{m}= double(P);
      posRate{m}=double(R) ;     
      posTime{m}=double(t);
%       tmpL=[];
%       tmpL(1:2:2*N_Node,1)=Normal_L_packet';
%       tmpL(2:2:2*N_Node,1)= Emergency_L_packet';
%       KeseeB{m}=repmat(avePLRth',N_Node,1).*repmat((1-avePLRth'),N_Node,1).*double(R).*double(t)./tmpL;
      posMinSumEnergy(m)=double(obj);
      posCalTime(m)=toc;   %ͳ��ÿ�μ���ʱ��
      toc    
       %��������ֵ�Ż����
     bakPosPower{m}= posPower{m};
     bakPosRate{m}= posRate{m};
     bakPosTime{m}= posTime{m};

 end;
 

for m=1:posNum
    
    tmpObj=inf; %�ҳ�ʹ�ù�����С������
    interNum=size(bakPosRate{m}(bakPosRate{m}<DataRate(4)-0.001),1);
    index1=find(bakPosRate{m}<DataRate(4));    
    tmpPosRate{m}=bakPosRate{m}; %����ֵ
    if interNum>0 %�����ʷ������
        posPower{m}=[];
        posRate{m}=[];
        posTime{m}=[];
        for n=1:power(2,interNum)
            chooseFlag=dec2bin(n-1,interNum)
            for tt=1:interNum
                 if chooseFlag(tt)=='1'
                     tmpPosRate{m}(index1(tt))=power(2,ceil(log2(ceil(bakPosRate{m}(index1(tt))./R_basic))))*R_basic;
                 elseif chooseFlag(tt)=='0'
                     tmpPosRate{m}(index1(tt))=power(2,floor(log2(floor(bakPosRate{m}(index1(tt))./R_basic))))*R_basic;
                 end;
            end;
           %% %%%%%%%%�������µ��������ʽ����Ż�
             P=sdpvar(N_Node*2,1);
             R=tmpPosRate{m}; %���ｫ
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
                    %% ����Լ��            
                        constr=[constr;QoS_PiR(2*(m-1)+1,i)<=P(NIndex)*R(NIndex)^(-1) ;QoS_PiR(2*(m-1)+2,i)<=P(EIndex)*R(EIndex)^(-1)];
                        constr=[constr;QoS_Rt(1,i)<=R(NIndex)*t(NIndex);QoS_Rt(2,i)<=R(EIndex)*t(EIndex)];
                        constr=[constr;QoS_iR(1,i)*R(NIndex)^(-1)+tmpV(NIndex)<=QoS_D(1,i)];
                        constr=[constr;QoS_N_RtRtiTmpV(1,i)*R(NIndex)*t(NIndex)*R(NIndex)*t(NIndex)*tmpV(NIndex)^(-1)+QoS_N_Con(1,i)<=QoS_N_Rt(1,i)*R(NIndex)*t(NIndex)];
                        constr=[constr;QoS_iR(2,i)*R(EIndex)^(-1)+tmpV(EIndex)<=QoS_D(2,i)];
                        constr=[constr;QoS_E_iRtTmpV(1,i)*R(EIndex)^(-1)*t(EIndex)^(-1)*tmpV(EIndex)^(-1)+QoS_E_RtiTmpV(1,i)*R(EIndex)*t(EIndex)*tmpV(EIndex)^(-1)+QoS_E_Con(1,i)<=QoS_E_Rt(1,i)*R(EIndex)*t(EIndex)]; 
                       % constr=[constr;DataRate(1)<=R(NIndex);DataRate(1)<=R(EIndex)];
                        %constr=[constr;R(NIndex)<=DataRate(4)+eps;R(EIndex)<=DataRate(4)+eps];
                        constr=[constr;P_tx_min<=P(NIndex);P_tx_min<=P(EIndex)];
                        constr=[constr;P(NIndex)<=P_tx_max;P(EIndex)<=P_tx_max];
              end; 
              constr=[constr;sum_t<=T_Frame];  
              disp(['-----------��',num2str(m),'�����ƣ���',chooseFlag,'״̬���Ż�-----------'])
              tic
              %solve the ggp
              solution2{m,n}= solvesdp( constr,obj);
              double(obj)
              double(R)'
              disp(['-----------��',num2str(m),'���Ż�����-----------'])
              if double(obj)<tmpObj && solution2{m,n}.problem~=0 %��ǰ������ѡ����Ի�ø�С��Ŀ��ֵ
                  posPower{m}= double(P);
                  posRate{m}=double(R)  ;    
                  posTime{m}=double(t);
                  tmpObj =double(obj);
              end;
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end; 
        
    end; 
end;

 
 

 
 