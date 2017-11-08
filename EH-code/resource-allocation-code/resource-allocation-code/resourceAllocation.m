function [posPower,posRate,posTime,posMinSumEnergy,posCalTime,KeseeB]=resourceAllocation()

%% 使用yalmip进行ggp求解delayTh,KeseeB,
%% 加载参数
channelPar
load('QoS.mat')
load('channel.mat')
a=2.4;%电路能耗和发射能耗相关参数
b=5.8; 
posNum=3; % 共三种姿势

 %进行求解
 for m=1:posNum
     
     % 设置变量
     P=sdpvar(N_Node*2,1);
     R=sdpvar(N_Node*2,1);
     t=sdpvar(N_Node*2,1);
     tmpV=sdpvar(N_Node*2,1);
     sum_t=sdpvar(1);
     obj=0; %建立一个空多项式
     constr=[]; %创建一个空矩阵
     %set constraints
     for i=1:N_Node 
             NIndex=(i-1)*2+1;
             EIndex=(i-1)*2+2;
             %累加分配的时间
             sum_t=sum_t+t(NIndex)+t(EIndex);
            %设置目标函数        
             obj=obj+((a+1)*P(NIndex)+b)*t(NIndex)+((a+1)*P(EIndex)+b)*t(EIndex);
            %% 设置约束            
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
      disp(['-----------第',num2str(m),'次优化开始-----------'])
      tic
      %solve the ggp
      solution = solvesdp( constr,obj);
      disp(['-----------第',num2str(m),'次优化结束-----------'])

      %% 统计解果
      posPower{m}= double(P)
      posRate{m}=double(R)      
      posTime{m}=double(t)
      tmpL=[];
      tmpL(1:2:2*N_Node,1)=Normal_L_packet';
      tmpL(2:2:2*N_Node,1)= Emergency_L_packet';
      KeseeB{m}=repmat(avePLRth',N_Node,1).*repmat((1-avePLRth'),N_Node,1).*double(R).*double(t)./tmpL;
      posMinSumEnergy(m)=double(obj);
      posCalTime(m)=toc;   %统计每次计算时间
      toc    
 end;

 
 