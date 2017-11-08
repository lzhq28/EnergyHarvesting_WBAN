function [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance4(PNoise,deltaPL)

%% 使用yalmip进行ggp求解delayTh,KeseeB,
%思路：
%第一步：重新调整损失权重
%第二步：对于速率值不为最大值的所有速率项，分别有两种选择：距离最近的大于它的可选的离散速率值和距离最近的小于它的离散速率值
%% 加载参数
% PNoise=-94
% deltaPL=30
channelPar(PNoise,deltaPL)
load(strcat('QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load('miuThNode.mat')
posNum=3; % 共三种姿势
    tmpPL(2:2:2*N_Node,1)=NoPL';
    tmpPL(1:2:2*N_Node,1)=NoPL';    

%第一步：根据丢包率约束找到门限的速率值
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
        
    %对得到的R值进行离散化   
    iniR=power(2,floor(log2(threholdR./R_basic))).*R_basic;
    iniR(iniR<DataRate(1))=DataRate(1); %将数据速率小于最小值时将其设置为最小数据速率
    iniR(iniR>DataRate(4))=DataRate(4);
    tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot);%计算总带宽
    %当分配的总时隙数大于T_Frame时将会对数据速率对重新分配
    weight=zeros(size(iniR));%初始化
    disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);    
    maxPL=30;
 
    
    %对QoS_PiR进行初始化  
    I0=(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise)>0;%找到初始状态的门限速率小于最小数据速率
    weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 方法一
     relaxFactor=min(1,0.08+(deltaPL./maxPL).*(1-0.08)); %这个效果还不错
     tmpQoS_PiR(I0)=(relaxFactor+(1-relaxFactor).*weight(I0))./iniR(I0);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%方法二
%     I2=find(I0==1)
%     if ~isempty(I2) %若非空
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

    weight(iniR==DataRate(4))=inf;%将已经设置为最大值的数据速率的weight设置为负无穷大,表示已经无法再进行向上调整
    targetR= iniR; %中间值
    deltaT=0.95;    
   
    while tmpT>deltaT*T_Frame   
        %筛选不为最大值项
        targetR=iniR;
        I0=((iniR~=DataRate(4)));
        targetR(I0)=2*targetR(I0);
        %计算权重因子,选择非负最小值
        weight=abs((10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise)-(10*log10(1./iniR)+10*log10(BandWidth)-tmpPL-PNoise))./(10*log10(bakQoS_PiR)+10*log10(BandWidth)-tmpPL-PNoise);
        weight(iniR==DataRate(4))=inf
        %寻找最小值
        [Y,I1]=min(weight);
        iniR(I1)=targetR(I1);
        disp(['posNum:',num2str(m),'  changeIndex:',num2str(I1)]);
        if Y==inf %表示所有理想发送节点的得到的门限数据速率都大于最大发送速率
            disp(['warning:all target data rates are larger than the max rate.'])
            %处理模块
            break;%跳出
        else   
            %%%%%%%%%%%%方法一
            tmpQoS_PiR(I1)=min((relaxFactor+(1-relaxFactor).*(weight(I1))),1)./iniR(I1)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%方法二
%             I3=find(tmpQoSAllNode{m}(:,ceil(I1/2))<1./iniR(I1))
%             if ~isempty(I3) 
%                 avePLRSet(I3(end));
%                tmpQoS_PiR(I1)= tmpQoSAllNode{m}(I3(end),ceil(I1/2))
%             else
%                tmpQoS_PiR(I1)=1./iniR(I1);
%            end;
%            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end; 
        tmpT=sum(ceil(tmpRata.*T_Frame./iniR./T_Slot).*T_Slot);%计算总带宽
        disp(['posNum:',num2str(m),'  tmpT:',num2str(tmpT)]);
    end;
    posRate{m}=iniR;     
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
          disp(['********************************************'])
          disp(['**************恭喜：优化无错误**************'])
          disp(['********************************************'])
      else
          disp(['********************************************'])
          disp(['**************可悲：优化存在错误************'])
          disp(['********************************************'])
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
 


 
 

 
 