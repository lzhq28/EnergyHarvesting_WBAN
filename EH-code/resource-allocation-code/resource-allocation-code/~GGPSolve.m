%% 使用yalmip进行ggp求解
%% 加载参数
GGPpar
channelPar
load('QoS.mat')
%其它参数的设置
N_ch=10; %超帧的个数
N_Node=5;   %定义节点的个数
% min_X_Shadow=0;
% step_X_Shadow=0.5;
% max_X_Shadow=min_X_Shadow+(N_ch-1)*step_X_Shadow;
 

 ProbPosture=[0.5,0.3,0.2];
 pos=1;%表示当前所处的姿势状态
 %进行求解
 for m=1:N_ch
     if m<= ProbPosture(1)*N_ch
         pos=1;
     elseif m<=(ProbPosture(1)+ProbPosture(2))*N_ch
         pos=2;
     else 
         pos=3;
     end;
  
    %每一帧内的阴影衰落不变，不同帧的阴影衰落为随机值
     X_Shadow_Real=(NodeKese(pos,:)'.*randn(N_Node,1));
     % 设置变量
     P=sdpvar(N_Node*2,1);
     R=sdpvar(N_Node*2,1);
     t=sdpvar(N_Node*2,1);
     tmpV=sdpvar(N_Node*2,1);
     sum_t=sdpvar(1);
     %创建目标函数--多项式
     obj=0; %建立一个空多项式
     constr=[]; %创建一个空矩阵
     status_Node_of_eachFrame=[];%用来存储每个包的产生和传输以及
     NodeSet=[1,2,3,4,5];%主要是用来确定哪些节点会因为阴影衰落较大而进行中断不发送数据
     for i=1:N_Node 
         if ~isempty(find(NodeSet==i))
             Normal_index=(i-1)*2+1;
             Emergency_index=(i-1)*2+2;
             %累加分配的时间
             sum_t=sum_t+t(Normal_index)+t(Emergency_index);
            %设置目标函数        
            obj=obj+((a+1)*P(Normal_index)+b)*t(Normal_index)+((a+1)*P(Emergency_index)+b)*t(Emergency_index);
            %% 设置约束            
                %阴影衰落
                constr=[constr;QoS_PiR(2*(pos-1)+1,i)<=P(Normal_index)*R(Normal_index)^(-1) ;QoS_PiR(2*(pos-1)+2,i)<=P(Emergency_index)*R(Emergency_index)^(-1)];
                %时延
                constr=[constr;QoS_Rt(1,i)<=R(Normal_index)*t(Normal_index);QoS_Rt(2,i)<=R(Emergency_index)*t(Emergency_index)];
                constr=[constr;QoS_iR(1,i)*R(Normal_index)^(-1)+tmpV(Normal_index)<=QoS_D(1,i)];
                constr=[constr;QoS_N_RtiTmpV(1,i)*R(Normal_index)*t(Normal_index)*tmpV(Normal_index)^(-1)+QoS_N_Con(1,i)<=QoS_N_Rt(1,i)*R(Normal_index)*t(Normal_index)];
                constr=[constr;QoS_iR(2,i)*R(Emergency_index)^(-1)+tmpV(Emergency_index)<=QoS_D(2,i)];
                constr=[constr;QoS_E_iRtTmpV(1,i)*R(Emergency_index)^(-1)*t(Emergency_index)^(-1)*tmpV(Emergency_index)^(-1)+QoS_E_iTmpV(1,i)*tmpV(Emergency_index)^(-1)+QoS_E_Con(1,i)<=QoS_E_Rt(1,i)*R(Emergency_index)*t(Emergency_index)]; 

    %             %速率约束
                constr=[constr;DataRate(1)<=R(Normal_index);DataRate(1)<=R(Emergency_index)];
                constr=[constr;R(Normal_index)<=DataRate(4);R(Emergency_index)<=DataRate(4)];
                %发射功率约束
                constr=[constr;P_tx_min<=P(Normal_index);P_tx_min<=P(Emergency_index)];
                constr=[constr;P(Normal_index)<=P_tx_max;P(Emergency_index)<=P_tx_max];
        end; 
     end;

      %总时长约束
      constr=[constr;sum_t<=T_Frame];  
      disp(['-----------第',num2str(m),'次优化开始-----------'])
      X_Shadow_Real
         %用于统计计算耗时
     tic
      %% 重要激动.....，进行求解
      solution = solvesdp( constr,obj);
      disp(['-----------第',num2str(m),'次优化结束-----------'])

      %% 统计解果
      Result_Power{m}= double(P)
      Result_Rate{m}=double(R)      
      Result_time{m}=double(t)
%       double(R)
%       double(t)
      Result_tmpV_real{m}=double(tmpV);
      Result_minSumEnergy(m)=double(obj);
      %计算单次计算耗时
      final_calTime(m)=toc;   %统计每次计算时间
      toc
      final_X_Shadow{m}=X_Shadow_Real; %统计每帧内的各个节点的阴影衰落     
      
 end;

 
 