function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance()

%% 使用yalmip进行ggp求解delayTh,KeseeB,
%思路：
%第一步：将功率值调节为最大值，然后得到相应的优化速率值
%第二步：对于速率值不为最大值的所有速率项，分别有两种选择：距离最近的大于它的可选的离散速率值和距离最近的小于它的离散速率值
%% 加载参数
channelPar
load('QoS.mat')
load('channel.mat')

posNum=3; % 共三种姿势


%第一步：将功率值调节为最大值，然后得到相应的优化速率值
%进行求解
 for m=1:posNum
     % 设置变量
     %P=sdpvar(N_Node*2,1);
     P=ones(N_Node*2,1);
     R=sdpvar(N_Node*2,1);
     %assign(R,repmat( DataRate(4),N_Node*2,1))
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
            % obj=obj-R(NIndex)-R(EIndex);
            %% 设置约束            
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
      disp(['-----------第',num2str(m),'次优化开始-----------'])
      tic
      %solve the ggp
      solution{m} = solvesdp( constr,obj);
      disp(['-----------第',num2str(m),'次优化结束-----------'])

      %% 统计解果
      posPower{m}= double(P);
      posRate{m}=double(R) ;     
      posTime{m}=double(t);
%       tmpL=[];
%       tmpL(1:2:2*N_Node,1)=Normal_L_packet';
%       tmpL(2:2:2*N_Node,1)= Emergency_L_packet';
%       KeseeB{m}=repmat(avePLRth',N_Node,1).*repmat((1-avePLRth'),N_Node,1).*double(R).*double(t)./tmpL;
      posMinSumEnergy(m)=double(obj);
      posCalTime(m)=toc;   %统计每次计算时间
      toc    
       %保存连续值优化结果
     bakPosPower{m}= posPower{m};
     bakPosRate{m}= posRate{m};
     bakPosTime{m}= posTime{m};

 end;
 

for m=1:posNum
    
    tmpObj=inf; %找出使得功率最小的速率
    interNum=size(bakPosRate{m}(bakPosRate{m}<DataRate(4)-0.001),1);
    index1=find(bakPosRate{m}<DataRate(4));    
    tmpPosRate{m}=bakPosRate{m}; %赋初值
    if interNum>0 %有速率非最大项
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
           %% %%%%%%%%按照最新的配置速率进行优化
             P=sdpvar(N_Node*2,1);
             R=tmpPosRate{m}; %这里将
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
                       % constr=[constr;DataRate(1)<=R(NIndex);DataRate(1)<=R(EIndex)];
                        %constr=[constr;R(NIndex)<=DataRate(4)+eps;R(EIndex)<=DataRate(4)+eps];
                        constr=[constr;P_tx_min<=P(NIndex);P_tx_min<=P(EIndex)];
                        constr=[constr;P(NIndex)<=P_tx_max;P(EIndex)<=P_tx_max];
              end; 
              constr=[constr;sum_t<=T_Frame];  
              disp(['-----------第',num2str(m),'个姿势，第',chooseFlag,'状态的优化-----------'])
              tic
              %solve the ggp
              solution2{m,n}= solvesdp( constr,obj);
              double(obj)
              double(R)'
              disp(['-----------第',num2str(m),'次优化结束-----------'])
              if double(obj)<tmpObj && solution2{m,n}.problem~=0 %当前的速率选择可以获得更小的目标值
                  posPower{m}= double(P);
                  posRate{m}=double(R)  ;    
                  posTime{m}=double(t);
                  tmpObj =double(obj);
              end;
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end; 
        
    end; 
end;

 
 

 
 