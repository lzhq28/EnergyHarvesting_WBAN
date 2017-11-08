function []=compareTPC(PNoise,deltaPL,T_L,T_H)
PLRInfo='./data/PLRN0.01E0.005'
load(strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_shadow_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_numPacket_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_optimalValue_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
probPosture=[0.5 0.3 0.2]; %不同姿势状态下的稳态概率
packetNormalInfo=[];
packetEmergencyInfo=[];
packetNormalInfo{N_Node}=[];  %统计包的信息 格式： ID ， cur Nch， PLR ，P ，t, R
packetEmergencyInfo{N_Node}=[]; 
curRandForPLRofNormal=[];
curRandForPLRofEmergency=[];
packetDelay=[]; %统计每个节点发送的每个包的丢包情况
packetDelay{N_Node}=[];

countNormalPacket=zeros(1,N_Node);
countEmergencyPacket=zeros(1,N_Node);

%% 循环-
    % 进行参数配置
    priorityTranFlag=1 %是否采用抢占式优先级排队策略，如果采用，将首先发送紧急包，只有紧急包发送接收后再发送普通包
    retranFlag=0
    showNode=1 ;% 要展示消息的节点，为0表示不显示
    retranCountN=zeros(1,N_Node);
    retranCountE=zeros(1,N_Node);
    retranNorMax=repmat([4],1,N_Node);     % 设置普通包的最大重传次数
    retranEmerMax=repmat([4],1,N_Node);     % 设置紧急包的最大重传次数
    queueNorMax=repmat([25],1,N_Node);  % 设置普通包的最大队列长度
    queueEmerMax=repmat([25],1,N_Node);     % 设置紧急包的最大队列长度
    packetNorBeginEnd{N_Node}=[];   % 数据包的开始和结束帧位置
    packetEmerBeginEnd{N_Node}=[];  % 紧急包的开始和结束位置
    
for m=1:N_ch
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%这里是对比试验的主要代码%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %基本参数
    a_d=0.8;
    a_u=0.6;
%     T_L=-63;%-65时系统性能还不错
%     T_H=-53;%-55时性能不错
    %根据信道信息分配资源，这里一般只对功率进行配置
    decideFlag=1; %为1时表示使用固定速率
    if decideFlag==1
            if m<= probPosture(1)*N_ch
                %采用固定的数据速率
                scheRate(1:N_Node,1,m)=DataRate(4);  
                scheRate(1:N_Node,2,m)=DataRate(4);  
            elseif m<=(probPosture(1)+probPosture(2))*N_ch 
              %采用固定的数据速率
                 scheRate(1:N_Node,1,m)=DataRate(4);  
                 scheRate(1:N_Node,2,m)=DataRate(4); 
            else
                   %采用固定的数据速率
                 scheRate(1:N_Node,1,m)=DataRate(4);  
                 scheRate(1:N_Node,2,m)=DataRate(4); 
            end;
    else
                if m<= probPosture(1)*N_ch
                %采用数据确定策略的结果
                    scheRate(1:N_Node,1,m)=posRate{1}(1:2:end,1);  
                    scheRate(1:N_Node,2,m)=posRate{1}(2:2:end,1);    
                elseif m<=(probPosture(1)+probPosture(2))*N_ch
                     %采用数据确定策略的结果
                     scheRate(1:N_Node,1,m)=posRate{2}(1:2:end,1); 
                     scheRate(1:N_Node,2,m)=posRate{2}(2:2:end,1); 
                else
                    %采用数据确定策略的结果
                     scheRate(1:N_Node,1,m)=posRate{3}(1:2:end,1);  
                     scheRate(1:N_Node,2,m)=posRate{3}(2:2:end,1);  
                end;
    end;
 
     scheTime(:,1,m)=ceil(numNormalPacket'.*Normal_L_packet'./scheRate(1:N_Node,1,m)./T_Slot).*T_Slot;%Normal_SourceRate.*T_Frame./scheRate(:,1,m);%满足吞吐量要求
     scheTime(:,2,m)=ceil(numEmergencyPacket'.*Emergency_L_packet'./scheRate(1:N_Node,2,m)./T_Slot).*T_Slot;% Emergency_SourceRate_Ave.*T_Frame./scheRate(:,2,m);%满足吞吐量要求
     
     if sum(sum(scheTime(:,:,m)))>T_Frame
          disp(['warnning in compareTPC: sum(t)=',num2str( sum(sum(scheTime(:,:,m)))),'>T_Frame '])
     end;
     if m==1
         schePower(:,1,m)=ones(N_Node,1);%初始化为1mW
         schePower(:,2,m)=ones(N_Node,1);%初始化为1mW
         schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%功率，dB为单位
         schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
         aveRSSINormal(1:N_Node,1)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};% 这里的阴影衰落是自己提出的实验的阴影衰落值
         aveRSSIEmergency(1:N_Node,1)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};% 这里的阴影衰落是自己提出的实验的阴影衰落值
     else
         schePower(:,1,m)=schePower(:,1,m-1);
         schePower(:,2,m)=schePower(:,2,m-1);
         schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%功率，dB为单位
         schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
         curRSSINormal(1:N_Node,m)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};% 这里的阴影衰落是自己提出的实验的阴影衰落值
         curRSSIEmergency(1:N_Node,m)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};% 这里的阴影衰落是自己提出的实验的阴影衰落值
         
         index1= find(curRSSINormal(:,m)<=aveRSSINormal(:,1));         
         if size(index1,1)~=0
             aveRSSINormal(index1,1)=a_d*curRSSINormal(index1,m)+(1-a_d)*aveRSSINormal(index1,1);
         end;
         index2= find(curRSSIEmergency(:,m)<=aveRSSIEmergency(:,1));
         if size(index2,1)~=0
             aveRSSIEmergency(index2,1)=a_d*curRSSIEmergency(index2,m)+(1-a_d)*aveRSSIEmergency(index2,1);
         end;
         
         index3=find(curRSSINormal(:,m)>aveRSSINormal(:,1));
         if size(index3,1)~=0
             aveRSSINormal(index3,1) = a_u*curRSSINormal(index3,1)+(1-a_u)*aveRSSINormal(index3,1);         
         end;
         index4=find(curRSSIEmergency(:,m)>aveRSSIEmergency(:,1));
         if size(index4,1)~=0
             aveRSSIEmergency(index4,1) = a_u*curRSSIEmergency(index4,1)+(1-a_u)*aveRSSIEmergency(index4,1);         
         end;
         
         index5=find(aveRSSINormal<T_L);
         if size(index5,1)~=0
             schePower(index5,1,m)=schePower(index5,1,m).*2;%功率加倍
             index6=find(schePower(:,1,m)>P_tx_max);
             if ~isempty(index6)
                 schePower(index6,1,m)=P_tx_max;
             end;
         end;
         index5=find(aveRSSIEmergency<T_L);
         if size(index5,1)~=0
             schePower(index5,2,m)=schePower(index5,2,m).*2;%功率加倍
             index6=find(schePower(:,2,m)>P_tx_max);
             if ~isempty(index6)
                 schePower(index6,2,m)=P_tx_max;
             end;
         end;
         
         index7=find(aveRSSINormal>T_H);
         if ~isempty(index7)
             schePower(index7,1,m)=schePower(index7,1,m)./2;%功率加倍
             index8=find(schePower(:,1,m)<P_tx_min);
             if ~isempty(index8)
                 schePower(index8,1,m)=P_tx_min;
             end;             
         end;
         index7=find(aveRSSIEmergency>T_H);
         if ~isempty(index7)
             schePower(index7,2,m)=schePower(index7,2,m)./2;%功率加倍
             index8=find(schePower(:,2,m)<P_tx_min);
             if ~isempty(index8)
                 schePower(index8,2,m)=P_tx_min;
             end;             
         end; 
     end;
     schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%功率，dB为单位
     schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
 


     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %数据入队列
     for i=1:N_Node
         countNormalPacket(1,i)=countNormalPacket(1,i)+curNumNormalPacket(m,i);%统计节点共产生多少包
         countEmergencyPacket(1,i)=countEmergencyPacket(1,i)+curNumEmergencyPacket(m,i);%统计节点共产生多少包
         if m==1  %第一次入队列，初始化队列
             queueNormalInfo(m,1,i)=1;
             queueNormalInfo(m,2,i)=countNormalPacket(1,i);
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);
             % 记录数据包的开始超值位置和结束位置，在开始超帧前等待的时间,发送包的时耗,最后节点的状态（1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃）
             packetNorBeginEnd{i}(1:queueNormalInfo(m,2,i),1)=m; %记录普通包的开始帧位置
             packetNorBeginEnd{i}(1:queueNormalInfo(m,2,i),3)=T_Frame*(1:queueNormalInfo(m,2,i))./(queueNormalInfo(m,2,i)+1);

             queueEmergencyInfo(m,1,i)=1;
             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);
             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);
              % 记录数据包开始和结束位置
             packetEmerBeginEnd{i}(1:queueEmergencyInfo(m,2,i),1)=m;
             packetEmerBeginEnd{i}(1:queueEmergencyInfo(m,2,i),3)=T_Frame*(1:queueEmergencyInfo(m,2,i))./(queueEmergencyInfo(m,2,i)+1);

         else
             queueNormalInfo(m,1,i)=queueNormalInfo(m-1,3,i); %上一帧待发送的位置为当前帧内队列的开始位置
             queueNormalInfo(m,2,i)=countNormalPacket(1,i); 
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);  
             % 记录数据包的开始超值位置和结束位置，在开始超帧前等待的时间
             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),1)=m; %记录普通包的开始帧位置
             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),3)=T_Frame*(1:curNumNormalPacket(m,i))./(curNumNormalPacket(m,i)+1);
             % 判断普通包队列是否溢出
             if  queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1>queueNorMax(i) %如果队列长度大于最大缓存长度将进行丢弃
                 if i==showNode
                    disp(strcat(['nodeInd:',num2str(i),',Nor beginInd:',num2str(queueNormalInfo(m,1,i)),',endInd:',num2str(queueNormalInfo(m,2,i))]))
                 end
                 tmp=queueNormalInfo(m,2,i)-queueNorMax(i)-1;
                 for delCN=queueNormalInfo(m,3,i):tmp-1
                     packetNormalInfo{i}(end+1,1)=delCN;
                     packetNormalInfo{i}(end,2)=m;%当前帧，方便后面求算排队时间
                     packetNormalInfo{i}(end,3)=1;%PLR 
                     packetNormalInfo{i}(end,4)=0;%P
                     packetNormalInfo{i}(end,5)=0;%t
                     packetNormalInfo{i}(end,6)=0;%R
                     packetNormalInfo{i}(end,7)=4;%直接丢弃
                     
                     % 对包的结束位置进行标记
                     packetNorBeginEnd{i}(delCN,2)=m;
                     packetNorBeginEnd{i}(delCN,5)=4;   %状态位4直接丢弃
                     
                 end
                 queueNormalInfo(m,1,i) = tmp;
                 queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);
             end
             
             queueEmergencyInfo(m,1,i)=queueEmergencyInfo(m-1,3,i);
             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);
             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);
             % 记录数据包的开始和结束位置queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i)
             packetEmerBeginEnd{i}(queueEmergencyInfo(m-1,2,i)+1:queueEmergencyInfo(m,2,i),1)=m;
             packetEmerBeginEnd{i}(queueEmergencyInfo(m-1,2,i)+1:queueEmergencyInfo(m,2,i),3)=T_Frame*(1:curNumEmergencyPacket(m,i))./(curNumEmergencyPacket(m,i)+1);
             % 判断队列是否溢出
             if queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1>queueEmerMax(i) %如果队列长度大于最大缓存长度，将进行丢弃
                 %disp(strcat(['nodeInd:',num2str(i),',Emer beginInd:',num2str(queueEmergencyInfo(m,1,i)),',endInd:',num2str(queueEmergencyInfo(m,2,i))]))
                 tmp=queueEmergencyInfo(m,2,i)-queueEmerMax(i)-1;
                 for delCE=queueEmergencyInfo(m,3,i):tmp-1
                    packetEmergencyInfo{i}(end+1,1)=delCE;%获得当前正在处理的包的ID，且传输包的信息增加一行
                    packetEmergencyInfo{i}(end,2)=m; %当前帧，方便后面求算排队时间
                    packetEmergencyInfo{i}(end,3)=1;%PLR 
                    packetEmergencyInfo{i}(end,4)=0;%P
                    packetEmergencyInfo{i}(end,5)=0;%t
                    packetEmergencyInfo{i}(end,6)=0;%R
                    packetEmergencyInfo{i}(end,7)=4; %直接丢弃
                    % 对包的位置进行标记
                    packetEmerBeginEnd{i}(delCE,2)=m;
                    packetEmerBeginEnd{i}(delCE,5)=4;   %队列满了直接丢弃
                 end
                 queueEmergencyInfo(m,1,i)=tmp;
                 queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);
             end
         end;        
     end;
     
    
    %发送包，将各种信息保存在packetNormalInfo和packetEmergencyInfo
     
    %计算各个节点的丢包率
    if m==1
       curSNRofNormal{m}=power(10,(schePowerDB(:,1,m)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,1,m));
       curSNRofEmergency{m}=power(10,(schePowerDB(:,2,m)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,2,m));
 
    else
        curSNRofNormal{m}=power(10,(schePowerDB(:,1,m-1)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,1,m));
        curSNRofEmergency{m}=power(10,(schePowerDB(:,2,m-1)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,2,m));

    end;
    DBPSKofNormal{m}=0.5*exp(-curSNRofNormal{m});
    DBPSKofNormal{m}=0.5*exp(-curSNRofEmergency{m});
    BCHofNormal{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);
    BCHofEmergency{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);
    curPLRofNormal{m}=1-power((1-BCHofNormal{m}),Normal_L_packet');
    curPLRofEmergency{m}=1-power((1-BCHofEmergency{m}),Emergency_L_packet');
    
    curNumTranNormal=floor(scheTime(:,1,m).*scheRate(:,1,m)./Normal_L_packet');%分配的时隙可以发送包的次数
    curNumTranEmergency=floor(scheTime(:,2,m).*scheRate(:,2,m)./Emergency_L_packet');%分配的时隙可以发送包的次数
    allNumTranEmergency=floor((scheTime(:,1,m)+scheTime(:,2,m)).*scheRate(:,2,m)./Emergency_L_packet');

    % 开始传输，将分为：1）考虑重传，2）不考虑重传，3）紧急包具有抢占式优先级
       for i=1:N_Node
           %紧急包传输
         if  priorityTranFlag %若采用抢占式
             tmpTranEmergency = allNumTranEmergency(i);
             tmpCursor=0;
         else
             tmpTranEmergency = curNumTranEmergency(i);
         end;
           %紧急包传输
         curRandForPLRofEmergency{m,i}=rand(tmpTranEmergency,1); %对每一次发送包都产生一个随机序列
         for j=1:tmpTranEmergency %逐个发送包，统计发送包的信息
            % disp(['[Emergency:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])
             if queueEmergencyInfo(m,3,i)<=queueEmergencyInfo(m,2,i) %队列中还有包要传输
                 %统计发送包的信息
                packetEmergencyInfo{i}(end+1,1)=queueEmergencyInfo(m,3,i);%获得当前正在处理的包的ID，且传输包的信息增加一行
                packetEmergencyInfo{i}(end,2)=m; %当前帧，方便后面求算排队时间
                packetEmergencyInfo{i}(end,3)=curPLRofEmergency{m}(i);%PLR 
                if m==1
                    packetEmergencyInfo{i}(end,4)=schePower(i,2,m);%P
                else
                    packetEmergencyInfo{i}(end,4)=schePower(i,2,m-1);%P
                end;
                packetEmergencyInfo{i}(end,5)=Emergency_L_packet(i)/scheRate(i,2,m);%t
                packetEmergencyInfo{i}(end,6)=scheRate(i,2,m);%R
                 if curPLRofEmergency{m}(i)<=curRandForPLRofEmergency{m,i}(j) %若生成的随机数大于计算的丢包率则表示包成功传输
                     packetEmergencyInfo{i}(end,7)=1;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                     if i==showNode
                        disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: success tran']))
                     end
                     % 对包结束位置进行
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),4)=Emergency_L_packet(i)/scheRate(i,2,m);
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=1;
                     
                     queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;%指向下一个包
                     if(retranFlag)
                         retranCountE(i)=0; %重传次数归零
                     end
                 else
                      %判断是否重传
                     if (retranFlag) %如果重传
                         retranCountE(i) = retranCountE(i)+1; % 重传次数加一
                         if(retranCountE(i) <= retranEmerMax(i)) % 重传次数小于最大传输次数，继续进行传输
                             if i==showNode
                                disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),', state: retran']))
                             end 
                            packetEmergencyInfo{i}(end,7)=2;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                         else
                             if i==showNode
                                disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),', state:discard']))
                             end
                             % 对包的位置进行标注
                             packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;
                             packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=3;%3表示重传超限丢弃
                             
                             packetEmergencyInfo{i}(end,7)=3;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1; %指向下一个包
                             retranCountE(i)=0; %重传次数归零
                         end 
                     else %如果不重传，则直接丢弃
                        if i==showNode
                            disp(strcat(['nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: directly discard']))
                        end
                        packetEmergencyInfo{i}(end,7)=4; %传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示不重传直接丢弃
                        % 对包状态进行标注
                        packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;
                        packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=4;
                        
                        queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;
                     end                   
                 end;
             else %如果队列中没有紧急包要传输
                 if priorityTranFlag
                     tmpCursor=j;
                     break;
                 end
             end;             
         end;
         %正常包传输
         if priorityTranFlag
             lastTime=((scheTime(i,1,m)+scheTime(i,2,m))-(tmpCursor-1)*Emergency_L_packet(i)/scheRate(i,2,m));% 出去紧急包发送剩下时间
             tmpTranNormal=floor(lastTime*scheRate(i,1,m)/Normal_L_packet(i));
             disp(strcat(['rest trans for normal:',num2str(tmpTranNormal)]))
         else
             tmpTranNormal=curNumTranNormal(i);
         end
         curRandForPLRofNormal{m,i}=rand(tmpTranNormal,1); %对每一次发送包都产生一个随机序列
         for j=1:tmpTranNormal %逐个发送包，统计发送包的信息
             %disp(['[Normal:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])
             if queueNormalInfo(m,3,i)<=queueNormalInfo(m,2,i) %队列中还有包要传输
                 %统计发送包的信息
                 packetNormalInfo{i}(end+1,1)=queueNormalInfo(m,3,i);%获得当前正在处理的包的ID，且传输包的信息增加一行
                 packetNormalInfo{i}(end,2)=m; %当前帧，方便后面求算排队时间
                 packetNormalInfo{i}(end,3)=curPLRofNormal{m}(i);%PLR 
                
                 if m==1
                      packetNormalInfo{i}(end,4)=schePower(i,1,m);%P
                 else
                      packetNormalInfo{i}(end,4)=schePower(i,1,m-1);%P
                 end;
                 packetNormalInfo{i}(end,5)=Normal_L_packet(i)/scheRate(i,1,m);%t
                 packetNormalInfo{i}(end,6)=scheRate(i,1,m);%R
                 if curPLRofNormal{m}(i)<=curRandForPLRofNormal{m,i}(j) %若生成的随机数大于计算的丢包率则表示包成功传输
                     packetNormalInfo{i}(end,7)=1;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                     if i==showNode
                          disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',normalPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),'state: success tran']))
                     end
                     % 对包的结束位置进行标注
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),4)=Normal_L_packet(i)/scheRate(i,1,m);  % 状态位1表示发送成功
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=1;  % 状态位1表示发送成功

                     queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%指向下一个包     
                     if (retranFlag)
                         retranCountN(i) = 0; %重传次数归零
                     end
                 else
                    % 判断是否重传
                     if (retranFlag)
                         retranCountN(i)=retranCountN(i)+1; %重传次数加一
                         if (retranCountN(i)<=retranNorMax(i)) %判断重传次数是否小于最大传输次数
                             packetNormalInfo{i}(end,7)=2; %传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                         else
                             packetNormalInfo{i}(end,7)=3;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                             % 对包的结束位置和状态位进行标注
                             packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;
                             packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=3; %状态位3表示重传超限
                             
                             queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%开始下一个包传输
                             retranCountN(i)=0; %重传次数归零
                         end
                     else
                         if i==showNode
                             disp(strcat(['nodeInd:',num2str(i),',normal PacketInd:',num2str(queueNormalInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),',state: directly discard']))
                         end
                         packetNormalInfo{i}(end,7)=4;%成功传输，状态位为1，2表示重传,3表示重传超限丢弃，4表示直接丢弃
                         % 对包的结束位置和状态位进行标注
                         packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;
                         packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=4; %状态位4：直接丢弃
                         queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;
                     end                  
                 end;                 
             end;  
         end;
     end;
end;
% %%计算性能
resultEnergyNormal=zeros(N_Node,1);
resultEnergyEmergency=zeros(N_Node,1);
% %平均丢包率，丢包的个数/总发送包的个数，
resultPLRofNormal=[];
resultPLRofEmergency=[];
packetDelayNormal=[];
packetDelayEmergency=[];
queueLengthNormal=[];
queueLengthEmergency=[];
DELAYMAX=99999999.0;
for i=1:N_Node
     %% 计算平均丢包率
        %普通包：平均丢包率:尝试发送的最大包的index-成功发送的包数量
        ind1=find(packetNorBeginEnd{i}(:,5)==1);
        ind2=find(packetNorBeginEnd{i}(:,5)>0);
        resultPLRofNormal(i)=(length(ind2)-length(ind1))/length(ind2);
        % 紧急包 
        ind1=find(packetEmerBeginEnd{i}(:,5)==1);
        ind2=find(packetEmerBeginEnd{i}(:,5)>0);
        resultPLRofEmergency(i)=(length(ind2)-length(ind1))/length(ind2);
        
    %% 计算时延，先统计每一个包的平均时延，然后再统计总的平均时延。 只计算成功传输的包的时延
        % 普通包时延
        for n=1:size(packetNorBeginEnd{i},1)
            if  packetNorBeginEnd{i}(n,5)==1
                packetDelayNormal{i}(n,1)=(packetNorBeginEnd{i}(n,2)-packetNorBeginEnd{i}(n,1))*T_Frame+packetNorBeginEnd{i}(n,3)+packetNorBeginEnd{i}(n,4);
            else
                packetDelayNormal{i}(n,1)=DELAYMAX; %如果包没有成功传输将其设置为很大的值
            end
        end
        ind=find(packetDelayNormal{i}~=DELAYMAX);
        resultNormalAveDelay(i)=mean(packetDelayNormal{i}(ind)); %计算平均时延
        resultNormalMaxDelay(i)=max(packetDelayNormal{i}(ind)); %统计最大时延
        % 紧急包时延
        for n=1:size(packetEmerBeginEnd{i},1)
            if packetEmerBeginEnd{i}(n,5)==1
                packetDelayEmergency{i}(n,1)=(packetEmerBeginEnd{i}(n,2)-packetEmerBeginEnd{i}(n,1))*T_Frame+packetEmerBeginEnd{i}(n,3)+packetEmerBeginEnd{i}(n,4);
            else
                packetDelayEmergency{i}(n,1)=DELAYMAX; %如果包没有传输成功将不统计该包的时延，将其设置为最大值
            end
        end
        ind=find(packetDelayEmergency{i}~=DELAYMAX);
        resultEmergencyAveDelay(i)=mean(packetDelayEmergency{i}(ind)); %计算平均时延
        resultEmergencyMaxDelay(i)=max(packetDelayEmergency{i}(ind)); %统计最大时延
    %% 统计总能耗
        % 普通包的能耗
        for n=1:packetNormalInfo{i}(end,1)
            ind=find(packetNormalInfo{i}(:,1)==n);
            resultEnergyNormal(i)= resultEnergyNormal(i)+(a+1)*packetNormalInfo{i}(ind,4)'*packetNormalInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetNormalInfo{i}(ind,5);
        end
        % 紧急包的能耗
        for n=1:packetEmergencyInfo{i}(end,1)
            ind=find(packetEmergencyInfo{i}(:,1)==n);
            resultEnergyEmergency(i)= resultEnergyEmergency(i)+(a+1)*packetEmergencyInfo{i}(ind,4)'*packetEmergencyInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetEmergencyInfo{i}(ind,5);
        end
    
     %统计队列在每一帧开始和发送结束时的包长
     for m=1:size(queueNormalInfo,1)      
         queueLengthNormal(m,1,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1;
         queueLengthNormal(m,2,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,3,i)+1; 
         queueLengthEmergency(m,1,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1;
         queueLengthEmergency(m,2,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,3,i)+1;
     end;
end;
TPCInfo=strcat('./data/TPC_TL',num2str(T_L),'_TH',num2str(T_H))
save(strcat(TPCInfo,'_all2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'));%保存所有的数据
save(strcat(TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'result*','packetDelayNormal','packetDelayEmergency');