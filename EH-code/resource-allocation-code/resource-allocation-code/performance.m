function [resultPLRofNormal,resultPLRofEmergency,resultEnergyNormal, resultEnergyEmergency, resultNormalAveDelay, resultEmergencyAveDelay]=performance(retranAndPriInfo,PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT)

%% 性能测试，平均丢包率，时延和能耗

%% test 

% shadowAndNumPacketPATH='./data/shadowAndNumPacket.mat';

% load(shadowAndNumPacketPATH)

%% 加载数据

%     % 加载信道参数和优化问题中的QoS门限参数

    PLRInfo=strcat('./data/PLRN',num2str(avePLRth(1)),'E',num2str(avePLRth(2)))

    ChannelParPATH =strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')

    QoSParPATH=strcat(PLRInfo,'_QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')

    % 计算信道参数和QoS门限

    channelQoSPar(PNoise,deltaPL,miuTh,avePLRth)

    load(ChannelParPATH)

    load(QoSParPATH)

 

    % 加载阴影衰落和包产生情况

    reCalculate=0

    [X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(reCalculate);

%% 进行资功率，速率，时隙等计算

    [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance5(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);

%% 进行性能计算

    format long %开启高精度，设置为小数点后9位

    save(strcat(PLRInfo,'_optimalValue_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'pos*')



    packetNormalInfo=[];

    packetEmergencyInfo=[];

    packetNormalInfo{N_Node}=[];  %统计包的信息 格式： ID ， cur Nch， PLR ，P ，t, R

    packetEmergencyInfo{N_Node}=[]; 



    queueNormalInfo=[];% queue 格式 : 节点到达所分配时隙时的队列开始的位置，结束的位置，在时隙内发送包时不断变化的待处理的包的位置

    queueEmergencyInfo=[];% queue 格式 : 节点到达所分配时隙时的队列开始的位置，结束的位置，在时隙内发送包时不断变化的待处理的包的位置

    curRandForPLRofNormal=[];

    curRandForPLRofEmergency=[];



    packetDelay=[]; %统计每个节点发送的每个包的丢包情况

    packetDelay{N_Node}=[];

    for i=1:3

         schePower(:,1,i)=posPower{i}(1:2:end,1);  %正常通信包的发送功率

         schePower(:,2,i)=posPower{i}(2:2:end,1);  %紧急通信包的发送功率

         schePowerDB(:,1,i)=10*log10(posPower{i}(1:2:end,1));

         schePowerDB(:,2,i)=10*log10(posPower{i}(2:2:end,1));

         scheRate(:,1,i)=posRate{i}(1:2:end,1); %后面需要进行离散化，先假设可以连续调节速率

         scheRate(:,2,i)=posRate{i}(2:2:end,1);

         scheTime(:,1,i)=ceil(posTime{i}(1:2:end,1)./T_Slot).*T_Slot;

         scheTime(:,2,i)=ceil(posTime{i}(2:2:end,1)./T_Slot).*T_Slot;



         %如果分配的时隙不能发送一个包，则分配一个包的时隙大小

         index11=floor(scheTime(:,1,i).*scheRate(:,1,i)./Normal_L_packet')<1;

         if sum(index11)

              scheTime(index11,1,i)=ceil(Normal_L_packet(index11)'./scheRate(index11,1,i)./T_Slot).*T_Slot;

         end;

         index22=floor(scheTime(:,2,i).*scheRate(:,2,i)./Emergency_L_packet')<1;

         if sum(index22)

             scheTime(index22,2,i)=ceil(Emergency_L_packet(index22)'./scheRate(index22,2,i)./T_Slot).*T_Slot;

         end

         %对分配的时间进行小心处理，防止出现总时间大于超帧的情况

         if sum(sum(scheTime(:,:,i)))>T_Frame

              disp(['warnning in performance: sum(t)',num2str(sum(sum(scheTime(:,:,i)))),'>T_Frame in pos-',num2str(i)])

         end;

    end;



    countNormalPacket=zeros(1,N_Node);

    countEmergencyPacket=zeros(1,N_Node);

%% 循环进行仿真

%     priorityTranFlag=1 %是否采用抢占式优先级排队策略，如果采用，将首先发送紧急包，只有紧急包发送接收后再发送普通包

%     retranFlagN=1

%     retranFlagE=1

%     showNode=0 ;% 要展示消息的节点，为0表示不显示

%     retranCountN=zeros(1,N_Node);

%     retranCountE=zeros(1,N_Node);

%     retranNorMax=repmat([3],1,N_Node);     % 设置普通包的最大重传次数

%     retranEmerMax=repmat([3],1,N_Node);     % 设置紧急包的最大重传次数

%     queueNorMax=repmat([25],1,N_Node);  % 设置普通包的最大队列长度

%     queueEmerMax=repmat([25],1,N_Node);     % 设置紧急包的最大队列长度

%     packetNorBeginEnd{N_Node}=[];   % 数据包的开始和结束帧位置

%     packetEmerBeginEnd{N_Node}=[];  % 紧急包的开始和结束位置

    priorityTranFlag= retranAndPriInfo.priorityTranFlag %是否采用抢占式优先级排队策略，如果采用，将首先发送紧急包，只有紧急包发送接收后再发送普通包

    retranFlagN= retranAndPriInfo.retranFlagN

    retranFlagE=retranAndPriInfo.retranFlagE

    showNode=0 ;% 要展示消息的节点，为0表示不显示

    retranCountN=zeros(1,N_Node);

    retranCountE=zeros(1,N_Node);

    retranNorMax=retranAndPriInfo.retranNorMax;     % 设置普通包的最大重传次数

    retranEmerMax=retranAndPriInfo.retranEmerMax;     % 设置紧急包的最大重传次数

    queueNorMax=retranAndPriInfo.queueNorMax;  % 设置普通包的最大队列长度

    queueEmerMax=retranAndPriInfo.queueEmerMax;     % 设置紧急包的最大队列长度

    packetNorBeginEnd{N_Node}=[];   % 数据包的开始和结束帧位置

    packetEmerBeginEnd{N_Node}=[];  % 紧急包的开始和结束位置



    for m=1:N_ch

    if(mod(m,100)==0)

        disp(strcat(['进度：',num2str((m/N_ch*1.0))]))

    end

    % 获取当前姿势

     pos=posSeries(m);



     %数据入队列

     for i=1:N_Node

         countNormalPacket(1,i)=countNormalPacket(1,i)+curNumNormalPacket(m,i);%统计节点共产生多少包

         countEmergencyPacket(1,i)=countEmergencyPacket(1,i)+curNumEmergencyPacket(m,i);%统计节点共产生多少包

         if m==1  %第一次入队列，初始化队列： queueNormalInfo=[beginIndex,endIndex,curIndex]

             queueNormalInfo(m,1,i)=1;

             queueNormalInfo(m,2,i)=countNormalPacket(1,i);

             queueNormalInfo(m,3,i)= queueNormalInfo(m,1,i);

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

             queueNormalInfo(m,1,i)=queueNormalInfo(m-1,3,i); % 上一帧待发送的位置为当前帧内队列的开始位置

             queueNormalInfo(m,2,i)=countNormalPacket(1,i); 

             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i); 

             % 记录数据包的开始超值位置和结束位置，在开始超帧前等待的时间

             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),1)=m; %记录普通包的开始帧位置

             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),3)=T_Frame*(1:curNumNormalPacket(m,i))./(curNumNormalPacket(m,i)+1);

             

             % 判断普通包队列是否溢出

             if  queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1>queueNorMax(i)  % 如果队列长度大于最大缓存长度将进行丢弃

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

    curSNRofNormal{m}=power(10,(schePowerDB(:,1,pos)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,1,pos));

    curSNRofEmergency{m}=power(10,(schePowerDB(:,2,pos)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,2,pos));

    DBPSKofNormal{m}=0.5*exp(-curSNRofNormal{m});

    DBPSKofNormal{m}=0.5*exp(-curSNRofEmergency{m});

    BCHofNormal{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);

    BCHofEmergency{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);

    curPLRofNormal{m}=1-power((1-BCHofNormal{m}),Normal_L_packet');

    curPLRofEmergency{m}=1-power((1-BCHofEmergency{m}),Emergency_L_packet');

    curNumTranNormal=floor(scheTime(:,1,pos).*scheRate(:,1,pos)./Normal_L_packet');%分配的时隙可以发送包的次数

    curNumTranEmergency=floor(scheTime(:,2,pos).*scheRate(:,2,pos)./Emergency_L_packet');%分配的时隙可以发送包的次数

    allNumTranEmergency=floor((scheTime(:,1,pos)+scheTime(:,2,pos)).*scheRate(:,2,pos)./Emergency_L_packet');



    % 开始传输，将分为：1）考虑重传，2）不考虑重传，3）紧急包具有抢占式优先级

     for i=1:N_Node

         %紧急包传输

         if  priorityTranFlag %若采用抢占式

             tmpTranEmergency = allNumTranEmergency(i);

             tmpCursor=0;

         else

             tmpTranEmergency = curNumTranEmergency(i);

         end;

         curRandForPLRofEmergency{m,i} = rand(tmpTranEmergency,1); %对每一次发送包都产生一个随机序列

         for j=1:tmpTranEmergency %逐个发送包，统计发送包的信息

            % disp(['[Emergency:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])

             if queueEmergencyInfo(m,3,i)<=queueEmergencyInfo(m,2,i) %队列中还有包要传输

                 %统计发送包的信息

                packetEmergencyInfo{i}(end+1,1)=queueEmergencyInfo(m,3,i);%获得当前正在处理的包的ID，且传输包的信息增加一行

                packetEmergencyInfo{i}(end,2)=m; %当前帧，方便后面求算排队时间

                packetEmergencyInfo{i}(end,3)=curPLRofEmergency{m}(i);%PLR 

                packetEmergencyInfo{i}(end,4)=schePower(i,2,pos);%P

                packetEmergencyInfo{i}(end,5)=Emergency_L_packet(i)/scheRate(i,2,pos);%t

                packetEmergencyInfo{i}(end,6)=scheRate(i,2,pos);%R

                 if curPLRofEmergency{m}(i)<=curRandForPLRofEmergency{m,i}(j) %若生成的随机数大于计算的丢包率则表示包成功传输

                     packetEmergencyInfo{i}(end,7)=1;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃

                     if i==showNode

                        disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: success tran']))

                     end

                     % 对包结束位置进行

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),4)=Emergency_L_packet(i)/scheRate(i,2,pos);

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=1;

                     

                     queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;%指向下一个包

                     if(retranFlagE)

                         retranCountE(i)=0; %重传次数归零

                     end

                 else %当传输失败时判断是否重传

                     %判断是否重传

                     if (retranFlagE) %如果重传

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

             lastTime=((scheTime(i,1,pos)+scheTime(i,2,pos))-(tmpCursor-1)*Emergency_L_packet(i)/scheRate(i,2,pos));% 出去紧急包发送剩下时间

             tmpTranNormal=floor(lastTime*scheRate(i,1,pos)/Normal_L_packet(i));

             % disp(strcat(['rest trans for normal:',num2str(tmpTranNormal)]))

         else

             tmpTranNormal=curNumTranNormal(i);

         end

         curRandForPLRofNormal{m,i}=rand(tmpTranNormal,1); %对每一次发送包都产生一个随机序列

         for j=1:tmpTranNormal %逐个发送包，统计发送包的信息

             %disp(['[Normal:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])

             if queueNormalInfo(m,3,i)<=queueNormalInfo(m,2,i) % 队列中还有包要传输

                 %统计发送包的信息

                 packetNormalInfo{i}(end+1,1)=queueNormalInfo(m,3,i);%获得当前正在处理的包的ID，且传输包的信息增加一行

                 packetNormalInfo{i}(end,2)=m; %当前帧，方便后面求算排队时间

                 packetNormalInfo{i}(end,3)=curPLRofNormal{m}(i);%PLR 

                 packetNormalInfo{i}(end,4)=schePower(i,1,pos);%P

                 packetNormalInfo{i}(end,5)=Normal_L_packet(i)/scheRate(i,1,pos);%t

                 packetNormalInfo{i}(end,6)=scheRate(i,1,pos);%R

                 if curPLRofNormal{m}(i)<=curRandForPLRofNormal{m,i}(j) %若生成的随机数大于计算的丢包率则表示包成功传输

                     packetNormalInfo{i}(end,7)=1;%传输状态位，1表示传输成功，2表示重传,3表示重传超限丢弃，4表示直接丢弃

                     if i==showNode

                          disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',normalPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),'state: success tran']))

                     end

                     % 对包的结束位置进行标注

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),4)=Normal_L_packet(i)/scheRate(i,1,pos);  % 状态位1表示发送成功

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=1;  % 状态位1表示发送成功

                     

                     queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%指向下一个包 

                     if (retranFlagN)

                         retranCountN(i)=0; %重传次数归零

                     end

                 else

                     % 判断是否重传

                     if (retranFlagN)

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



%%计算性能

resultEnergyNormal=zeros(N_Node,1);

resultEnergyEmergency=zeros(N_Node,1);

%平均丢包率，丢包的个数/总发送包的个数，

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

    

     %% 统计队列在每一帧开始和发送结束时的包长

     for m=1:size(queueNormalInfo,1)      

         queueLengthNormal(m,1,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1;

         queueLengthNormal(m,2,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,3,i)+1; 

         queueLengthEmergency(m,1,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1;

         queueLengthEmergency(m,2,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,3,i)+1;

     end; 

end;

    %%

%     figure

%     plot(reshape(queueLengthEmergency(:,2,2),size(queueLengthEmergency(:,2,2),1),1))

    %保存结果

    save(strcat(PLRInfo,'_finalResult0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'result*','packetDelayNormal','packetDelayEmergency')

    save(strcat(PLRInfo,'_shadow_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'X_Shadow_Real')

    save(strcat(PLRInfo,'_numPacket_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'curNumNormalPacket','curNumEmergencyPacket')

    save(strcat(PLRInfo,'_all0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))







