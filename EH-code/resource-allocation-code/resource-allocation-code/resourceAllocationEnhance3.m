function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance3(PNoise,deltaPL)

%% 使用yalmip进行ggp求解delayTh,KeseeB,
%思路：
%第一步： 根据策略选择数据速率
%第二步：对于速率值不为最大值的所有速率项，分别有两种选择：距离最近的大于它的可选的离散速率值和距离最近的小于它的离散速率值
%% 加载参数
% PNoise=-94
% deltaPL=20
channelPar(PNoise,deltaPL)
load(strcat('QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
posNum=3; % 共三种姿势

%第一步：根据丢包率约束找到门限的速率值
for m=1:posNum    
    tmpRata(1:2:2*N_Node,1)=Normal_SourceRate';
    tmpRata(2:2:2*N_Node,1)=Emergency_SourceRate_Ave';
    %QoS
    bakQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';
    bakQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    tmpQoS_PiR(1:2:2*N_Node,1)=QoS_PiR(2*(m-1)+1,:)';    
    tmpQoS_PiR(2:2:2*N_Node,1)=QoS_PiR(2*m,:)';
    tmpR1=P_tx_max./tmpQoS_PiR;
        
    %对得到的R值进行离散化   
    tmpR2=power(2,floor(log2(tmpR1./R_basic))).*R_basic;
    tmpR2(tmpR2<DataRate(1))=DataRate(1); %将数据速率小于最小值时将其设置为最小数据速率
    tmpR2(tmpR2>DataRate(4))=DataRate(4);
    tmpT=sum(ceil(tmpRata.*T_Frame./tmpR2./T_Slot).*T_Slot);%计算总带宽
    %当分配的总时隙数大于T_Frame时将会对数据速率对重新分配
    weight=zeros(size(tmpR2));%初始化
    disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
    
    
    weight=tmpRata.*T_Frame.*((1-tmpR2./tmpR1).*tmpQoS_PiR)./tmpR2;
    weight(tmpR2==DataRate(4))=-inf;%将已经设置为最大值的数据速率的weight设置为负无穷大,表示已经无法再进行向上调整
    I0=(tmpR2==DataRate(1));%找到第一次为数据速率为最小值，这些数据速率对应的权重应该减少其权重值、
    weight(I0)=1/20.*weight(I0);%将权重值设置为原来的值得factor倍，这里是经验值
    deltaQ=0.3;
    tmpQoS_PiR(I0)=deltaQ*1./tmpR2(I0);
    deltaT=0.98;    
    while tmpT>deltaT*T_Frame        
        deltaQ=0.5;
        %选择权重最大项，将其该速率调整为原来的两倍
        if sum(weight~=-inf)~=0 %如果存在数据速率没调到最大值的情况            
            if sum(weight>0)~=0 %如果还有可以未上调过的节点
                [Y I]=sort(weight,'descend');%找到最大weight的点
                if tmpR2(I(1))~=DataRate(4) %再次判断是否是最大值
                    tmpR2(I(1))=tmpR2(I(1))*2;
                    %deltaQ=(max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))-min(1/tmpR2(I(1)),bakQoS_PiR(I(1))))./max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))
                    tmpQoS_PiR(I(1))=min(tmpQoS_PiR(I(1)),deltaQ*1/tmpR2(I(1)));%这里可以进行设计，将PLR约束值设置为原有约束值或者最大功率满足条件的约束值
                    disp(['posNum:',num2str(m),'  changeIndex:',num2str(I(1))]);
                else 
                    tmpQoS_PiR(I(1))=deltaQ*1./tmpR2(I(1));                                                                                                    
                end;
            else %weight 均为负数时，将设置那些不为0的值，按照节点的绝对值
                I0=(weight~=-inf);
                weight(I0)=abs(weight(I0));
                [Y I]=sort(weight,'descend');
                if tmpR2(I(1))~=DataRate(4) %再次判断是否是最大值
                    tmpR2(I(1))=tmpR2(I(1))*2;
                    %deltaQ=(max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))-min(1/tmpR2(I(1)),bakQoS_PiR(I(1))))./max(1/tmpR2(I(1)),bakQoS_PiR(I(1)))
                    tmpQoS_PiR(I(1))=min(tmpQoS_PiR(I(1)),deltaQ*1/tmpR2(I(1)));%这里可以进行设计，将PLR约束值设置为原有约束值或者最大功率满足条件的约束值
                    disp(['posNum:',num2str(m),'  changeIndex:',num2str(I(1))]);
                else 
                    tmpQoS_PiR(I(1))=deltaQ*1./tmpR2(I(1));                                                                                                    
                end;
                
            end;
            %不考虑紧急包和正常包的差异，而且不考虑节点的优先级         

        else %当全部的速率都设置为最大值时，1）将约束设置为，2）跳出循环
            disp(['posNum:',num2str(m),' all rates are max']);
            break; %跳出循环
        end;
        tmpT=sum(ceil(tmpRata.*T_Frame./tmpR2./T_Slot).*T_Slot);%计算总带宽
        disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
        weight=tmpRata.*T_Frame.*((1-tmpR2./tmpR1).*tmpQoS_PiR)./tmpR2;
        weight(tmpR2==DataRate(4))=-inf;%将已经设置为最大值的数据速率的weight设置为负无穷大,表示已经无法再进行向上调整
    end;
    posRate{m}=tmpR2;
    QoS_PiR(2*(m-1)+1,:)=tmpQoS_PiR(1:2:2*N_Node,1)';
    QoS_PiR(2*m,:)=tmpQoS_PiR(2:2:2*N_Node,1)';
end;

%进行求解
 for m=1:posNum
     % 设置变量
     P=sdpvar(N_Node*2,1);    
     R=posRate{m};
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
      solution{m} = solvesdp( constr,obj);
      if solution{m}.problem==0
          disp(['****************************************'])
          disp(['**************恭喜：优化无错误**************'])
          disp(['****************************************'])
      else
          disp(['****************************************'])
          disp(['**************可悲：优化存在错误**************'])
          disp(['****************************************'])

      end;
      disp(['-----------第',num2str(m),'次优化结束-----------'])

      %% 统计解果
      %if solution{m}.problem==0 %如果可以找到优化结果
          posPower{m}= double(P);
          posRate{m}=double(R) ;     
          posTime{m}=double(t);         
          posMinSumEnergy(m)=double(obj);  
      %end;

%       tmpL=[];
%       tmpL(1:2:2*N_Node,1)=Normal_L_packet';
%       tmpL(2:2:2*N_Node,1)= Emergency_L_packet';
%       KeseeB{m}=repmat(avePLRth',N_Node,1).*repmat((1-avePLRth'),N_Node,1).*double(R).*double(t)./tmpL;

      posCalTime(m)=toc;   %统计每次计算时间
      toc    
       %保存连续值优化结果
         bakPosPower{m}= posPower{m};
         bakPosRate{m}= posRate{m};
         bakPosTime{m}= posTime{m};
         posPower{m}(posPower{m}>P_tx_max)=P_tx_max;%这里将优化值中没有找到最优值时，功率大于最大值
         if sum(sum(posTime{m}))>T_Frame
          disp(['warnning in performance: sum(t)',num2str(sum(sum(posTime{m}))),'>T_Frame in pos-',num2str(i)])
         end;
 end;
 


 
 

 
 