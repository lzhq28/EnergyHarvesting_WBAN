function [resultPLRofNormal,resultPLRofEmergency,resultEnergyNormal, resultEnergyEmergency, resultNormalAveDelay, resultEmergencyAveDelay]=performance(retranAndPriInfo,PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT)

%% ���ܲ��ԣ�ƽ�������ʣ�ʱ�Ӻ��ܺ�

%% test 

% shadowAndNumPacketPATH='./data/shadowAndNumPacket.mat';

% load(shadowAndNumPacketPATH)

%% ��������

%     % �����ŵ��������Ż������е�QoS���޲���

    PLRInfo=strcat('./data/PLRN',num2str(avePLRth(1)),'E',num2str(avePLRth(2)))

    ChannelParPATH =strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')

    QoSParPATH=strcat(PLRInfo,'_QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')

    % �����ŵ�������QoS����

    channelQoSPar(PNoise,deltaPL,miuTh,avePLRth)

    load(ChannelParPATH)

    load(QoSParPATH)

 

    % ������Ӱ˥��Ͱ��������

    reCalculate=0

    [X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(reCalculate);

%% �����ʹ��ʣ����ʣ�ʱ϶�ȼ���

    [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance5(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);

%% �������ܼ���

    format long %�����߾��ȣ�����ΪС�����9λ

    save(strcat(PLRInfo,'_optimalValue_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'pos*')



    packetNormalInfo=[];

    packetEmergencyInfo=[];

    packetNormalInfo{N_Node}=[];  %ͳ�ư�����Ϣ ��ʽ�� ID �� cur Nch�� PLR ��P ��t, R

    packetEmergencyInfo{N_Node}=[]; 



    queueNormalInfo=[];% queue ��ʽ : �ڵ㵽��������ʱ϶ʱ�Ķ��п�ʼ��λ�ã�������λ�ã���ʱ϶�ڷ��Ͱ�ʱ���ϱ仯�Ĵ�����İ���λ��

    queueEmergencyInfo=[];% queue ��ʽ : �ڵ㵽��������ʱ϶ʱ�Ķ��п�ʼ��λ�ã�������λ�ã���ʱ϶�ڷ��Ͱ�ʱ���ϱ仯�Ĵ�����İ���λ��

    curRandForPLRofNormal=[];

    curRandForPLRofEmergency=[];



    packetDelay=[]; %ͳ��ÿ���ڵ㷢�͵�ÿ�����Ķ������

    packetDelay{N_Node}=[];

    for i=1:3

         schePower(:,1,i)=posPower{i}(1:2:end,1);  %����ͨ�Ű��ķ��͹���

         schePower(:,2,i)=posPower{i}(2:2:end,1);  %����ͨ�Ű��ķ��͹���

         schePowerDB(:,1,i)=10*log10(posPower{i}(1:2:end,1));

         schePowerDB(:,2,i)=10*log10(posPower{i}(2:2:end,1));

         scheRate(:,1,i)=posRate{i}(1:2:end,1); %������Ҫ������ɢ�����ȼ������������������

         scheRate(:,2,i)=posRate{i}(2:2:end,1);

         scheTime(:,1,i)=ceil(posTime{i}(1:2:end,1)./T_Slot).*T_Slot;

         scheTime(:,2,i)=ceil(posTime{i}(2:2:end,1)./T_Slot).*T_Slot;



         %��������ʱ϶���ܷ���һ�����������һ������ʱ϶��С

         index11=floor(scheTime(:,1,i).*scheRate(:,1,i)./Normal_L_packet')<1;

         if sum(index11)

              scheTime(index11,1,i)=ceil(Normal_L_packet(index11)'./scheRate(index11,1,i)./T_Slot).*T_Slot;

         end;

         index22=floor(scheTime(:,2,i).*scheRate(:,2,i)./Emergency_L_packet')<1;

         if sum(index22)

             scheTime(index22,2,i)=ceil(Emergency_L_packet(index22)'./scheRate(index22,2,i)./T_Slot).*T_Slot;

         end

         %�Է����ʱ�����С�Ĵ�����ֹ������ʱ����ڳ�֡�����

         if sum(sum(scheTime(:,:,i)))>T_Frame

              disp(['warnning in performance: sum(t)',num2str(sum(sum(scheTime(:,:,i)))),'>T_Frame in pos-',num2str(i)])

         end;

    end;



    countNormalPacket=zeros(1,N_Node);

    countEmergencyPacket=zeros(1,N_Node);

%% ѭ�����з���

%     priorityTranFlag=1 %�Ƿ������ռʽ���ȼ��ŶӲ��ԣ�������ã������ȷ��ͽ�������ֻ�н��������ͽ��պ��ٷ�����ͨ��

%     retranFlagN=1

%     retranFlagE=1

%     showNode=0 ;% Ҫչʾ��Ϣ�Ľڵ㣬Ϊ0��ʾ����ʾ

%     retranCountN=zeros(1,N_Node);

%     retranCountE=zeros(1,N_Node);

%     retranNorMax=repmat([3],1,N_Node);     % ������ͨ��������ش�����

%     retranEmerMax=repmat([3],1,N_Node);     % ���ý�����������ش�����

%     queueNorMax=repmat([25],1,N_Node);  % ������ͨ���������г���

%     queueEmerMax=repmat([25],1,N_Node);     % ���ý������������г���

%     packetNorBeginEnd{N_Node}=[];   % ���ݰ��Ŀ�ʼ�ͽ���֡λ��

%     packetEmerBeginEnd{N_Node}=[];  % �������Ŀ�ʼ�ͽ���λ��

    priorityTranFlag= retranAndPriInfo.priorityTranFlag %�Ƿ������ռʽ���ȼ��ŶӲ��ԣ�������ã������ȷ��ͽ�������ֻ�н��������ͽ��պ��ٷ�����ͨ��

    retranFlagN= retranAndPriInfo.retranFlagN

    retranFlagE=retranAndPriInfo.retranFlagE

    showNode=0 ;% Ҫչʾ��Ϣ�Ľڵ㣬Ϊ0��ʾ����ʾ

    retranCountN=zeros(1,N_Node);

    retranCountE=zeros(1,N_Node);

    retranNorMax=retranAndPriInfo.retranNorMax;     % ������ͨ��������ش�����

    retranEmerMax=retranAndPriInfo.retranEmerMax;     % ���ý�����������ش�����

    queueNorMax=retranAndPriInfo.queueNorMax;  % ������ͨ���������г���

    queueEmerMax=retranAndPriInfo.queueEmerMax;     % ���ý������������г���

    packetNorBeginEnd{N_Node}=[];   % ���ݰ��Ŀ�ʼ�ͽ���֡λ��

    packetEmerBeginEnd{N_Node}=[];  % �������Ŀ�ʼ�ͽ���λ��



    for m=1:N_ch

    if(mod(m,100)==0)

        disp(strcat(['���ȣ�',num2str((m/N_ch*1.0))]))

    end

    % ��ȡ��ǰ����

     pos=posSeries(m);



     %���������

     for i=1:N_Node

         countNormalPacket(1,i)=countNormalPacket(1,i)+curNumNormalPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�

         countEmergencyPacket(1,i)=countEmergencyPacket(1,i)+curNumEmergencyPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�

         if m==1  %��һ������У���ʼ�����У� queueNormalInfo=[beginIndex,endIndex,curIndex]

             queueNormalInfo(m,1,i)=1;

             queueNormalInfo(m,2,i)=countNormalPacket(1,i);

             queueNormalInfo(m,3,i)= queueNormalInfo(m,1,i);

             % ��¼���ݰ��Ŀ�ʼ��ֵλ�úͽ���λ�ã��ڿ�ʼ��֡ǰ�ȴ���ʱ��,���Ͱ���ʱ��,���ڵ��״̬��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ�����

             packetNorBeginEnd{i}(1:queueNormalInfo(m,2,i),1)=m; %��¼��ͨ���Ŀ�ʼ֡λ��

             packetNorBeginEnd{i}(1:queueNormalInfo(m,2,i),3)=T_Frame*(1:queueNormalInfo(m,2,i))./(queueNormalInfo(m,2,i)+1);

             

             queueEmergencyInfo(m,1,i)=1;

             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);

             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);

             % ��¼���ݰ���ʼ�ͽ���λ��

             packetEmerBeginEnd{i}(1:queueEmergencyInfo(m,2,i),1)=m;

             packetEmerBeginEnd{i}(1:queueEmergencyInfo(m,2,i),3)=T_Frame*(1:queueEmergencyInfo(m,2,i))./(queueEmergencyInfo(m,2,i)+1);

         else

             queueNormalInfo(m,1,i)=queueNormalInfo(m-1,3,i); % ��һ֡�����͵�λ��Ϊ��ǰ֡�ڶ��еĿ�ʼλ��

             queueNormalInfo(m,2,i)=countNormalPacket(1,i); 

             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i); 

             % ��¼���ݰ��Ŀ�ʼ��ֵλ�úͽ���λ�ã��ڿ�ʼ��֡ǰ�ȴ���ʱ��

             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),1)=m; %��¼��ͨ���Ŀ�ʼ֡λ��

             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),3)=T_Frame*(1:curNumNormalPacket(m,i))./(curNumNormalPacket(m,i)+1);

             

             % �ж���ͨ�������Ƿ����

             if  queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1>queueNorMax(i)  % ������г��ȴ�����󻺴泤�Ƚ����ж���

                 if i==showNode

                    disp(strcat(['nodeInd:',num2str(i),',Nor beginInd:',num2str(queueNormalInfo(m,1,i)),',endInd:',num2str(queueNormalInfo(m,2,i))]))

                 end

                 tmp=queueNormalInfo(m,2,i)-queueNorMax(i)-1;

                 for delCN=queueNormalInfo(m,3,i):tmp-1

                     packetNormalInfo{i}(end+1,1)=delCN;

                     packetNormalInfo{i}(end,2)=m;%��ǰ֡��������������Ŷ�ʱ��

                     packetNormalInfo{i}(end,3)=1;%PLR 

                     packetNormalInfo{i}(end,4)=0;%P

                     packetNormalInfo{i}(end,5)=0;%t

                     packetNormalInfo{i}(end,6)=0;%R

                     packetNormalInfo{i}(end,7)=4;%ֱ�Ӷ���

                     

                     % �԰��Ľ���λ�ý��б��

                     packetNorBeginEnd{i}(delCN,2)=m;

                     packetNorBeginEnd{i}(delCN,5)=4;   %״̬λ4ֱ�Ӷ���

                     

                 end

                 queueNormalInfo(m,1,i) = tmp;

                 queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);

             end

             queueEmergencyInfo(m,1,i)=queueEmergencyInfo(m-1,3,i);

             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);

             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);

             % ��¼���ݰ��Ŀ�ʼ�ͽ���λ��queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i)

             packetEmerBeginEnd{i}(queueEmergencyInfo(m-1,2,i)+1:queueEmergencyInfo(m,2,i),1)=m;

             packetEmerBeginEnd{i}(queueEmergencyInfo(m-1,2,i)+1:queueEmergencyInfo(m,2,i),3)=T_Frame*(1:curNumEmergencyPacket(m,i))./(curNumEmergencyPacket(m,i)+1);

             % �ж϶����Ƿ����

             if queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1>queueEmerMax(i) %������г��ȴ�����󻺴泤�ȣ������ж���

                 %disp(strcat(['nodeInd:',num2str(i),',Emer beginInd:',num2str(queueEmergencyInfo(m,1,i)),',endInd:',num2str(queueEmergencyInfo(m,2,i))]))

                 tmp=queueEmergencyInfo(m,2,i)-queueEmerMax(i)-1;

                 for delCE=queueEmergencyInfo(m,3,i):tmp-1

                    packetEmergencyInfo{i}(end+1,1)=delCE;%��õ�ǰ���ڴ���İ���ID���Ҵ��������Ϣ����һ��

                    packetEmergencyInfo{i}(end,2)=m; %��ǰ֡��������������Ŷ�ʱ��

                    packetEmergencyInfo{i}(end,3)=1;%PLR 

                    packetEmergencyInfo{i}(end,4)=0;%P

                    packetEmergencyInfo{i}(end,5)=0;%t

                    packetEmergencyInfo{i}(end,6)=0;%R

                    packetEmergencyInfo{i}(end,7)=4; %ֱ�Ӷ���

                    % �԰���λ�ý��б��

                    packetEmerBeginEnd{i}(delCE,2)=m;

                    packetEmerBeginEnd{i}(delCE,5)=4;   %��������ֱ�Ӷ���

                 end

                 queueEmergencyInfo(m,1,i)=tmp;

                 queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);

             end

         end;        

     end;

     

    %���Ͱ�����������Ϣ������packetNormalInfo��packetEmergencyInfo

    %��������ڵ�Ķ�����

    curSNRofNormal{m}=power(10,(schePowerDB(:,1,pos)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,1,pos));

    curSNRofEmergency{m}=power(10,(schePowerDB(:,2,pos)-NoPL'- X_Shadow_Real{m}-PNoise)./10).*(BandWidth./scheRate(:,2,pos));

    DBPSKofNormal{m}=0.5*exp(-curSNRofNormal{m});

    DBPSKofNormal{m}=0.5*exp(-curSNRofEmergency{m});

    BCHofNormal{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);

    BCHofEmergency{m}=DBPSKofNormal{m}-DBPSKofNormal{m}.*power((1-DBPSKofNormal{m}),n_BCH_PSDU-1);

    curPLRofNormal{m}=1-power((1-BCHofNormal{m}),Normal_L_packet');

    curPLRofEmergency{m}=1-power((1-BCHofEmergency{m}),Emergency_L_packet');

    curNumTranNormal=floor(scheTime(:,1,pos).*scheRate(:,1,pos)./Normal_L_packet');%�����ʱ϶���Է��Ͱ��Ĵ���

    curNumTranEmergency=floor(scheTime(:,2,pos).*scheRate(:,2,pos)./Emergency_L_packet');%�����ʱ϶���Է��Ͱ��Ĵ���

    allNumTranEmergency=floor((scheTime(:,1,pos)+scheTime(:,2,pos)).*scheRate(:,2,pos)./Emergency_L_packet');



    % ��ʼ���䣬����Ϊ��1�������ش���2���������ش���3��������������ռʽ���ȼ�

     for i=1:N_Node

         %����������

         if  priorityTranFlag %��������ռʽ

             tmpTranEmergency = allNumTranEmergency(i);

             tmpCursor=0;

         else

             tmpTranEmergency = curNumTranEmergency(i);

         end;

         curRandForPLRofEmergency{m,i} = rand(tmpTranEmergency,1); %��ÿһ�η��Ͱ�������һ���������

         for j=1:tmpTranEmergency %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ

            % disp(['[Emergency:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])

             if queueEmergencyInfo(m,3,i)<=queueEmergencyInfo(m,2,i) %�����л��а�Ҫ����

                 %ͳ�Ʒ��Ͱ�����Ϣ

                packetEmergencyInfo{i}(end+1,1)=queueEmergencyInfo(m,3,i);%��õ�ǰ���ڴ���İ���ID���Ҵ��������Ϣ����һ��

                packetEmergencyInfo{i}(end,2)=m; %��ǰ֡��������������Ŷ�ʱ��

                packetEmergencyInfo{i}(end,3)=curPLRofEmergency{m}(i);%PLR 

                packetEmergencyInfo{i}(end,4)=schePower(i,2,pos);%P

                packetEmergencyInfo{i}(end,5)=Emergency_L_packet(i)/scheRate(i,2,pos);%t

                packetEmergencyInfo{i}(end,6)=scheRate(i,2,pos);%R

                 if curPLRofEmergency{m}(i)<=curRandForPLRofEmergency{m,i}(j) %�����ɵ���������ڼ���Ķ��������ʾ���ɹ�����

                     packetEmergencyInfo{i}(end,7)=1;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                     if i==showNode

                        disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: success tran']))

                     end

                     % �԰�����λ�ý���

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),4)=Emergency_L_packet(i)/scheRate(i,2,pos);

                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=1;

                     

                     queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;%ָ����һ����

                     if(retranFlagE)

                         retranCountE(i)=0; %�ش���������

                     end

                 else %������ʧ��ʱ�ж��Ƿ��ش�

                     %�ж��Ƿ��ش�

                     if (retranFlagE) %����ش�

                         retranCountE(i) = retranCountE(i)+1; % �ش�������һ

                         if(retranCountE(i) <= retranEmerMax(i)) % �ش�����С�������������������д���

                             if i==showNode

                                disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),', state: retran']))

                             end 

                            packetEmergencyInfo{i}(end,7)=2;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                         else

                             if i==showNode

                                disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),', state:discard']))

                             end

                             % �԰���λ�ý��б�ע

                             packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;

                             packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=3;%3��ʾ�ش����޶���

                             

                             packetEmergencyInfo{i}(end,7)=3;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1; %ָ����һ����

                             retranCountE(i)=0; %�ش���������

                         end 

                     else %������ش�����ֱ�Ӷ���

                        if i==showNode

                            disp(strcat(['nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: directly discard']))

                        end

                        packetEmergencyInfo{i}(end,7)=4; %����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾ���ش�ֱ�Ӷ���

                        % �԰�״̬���б�ע

                        packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;

                        packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=4;

                        

                        queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;

                     end

                 end;

             else %���������û�н�����Ҫ����

                 if priorityTranFlag

                     tmpCursor=j;

                     break;

                 end

             end;             

         end;

         %����������

         

         if priorityTranFlag

             lastTime=((scheTime(i,1,pos)+scheTime(i,2,pos))-(tmpCursor-1)*Emergency_L_packet(i)/scheRate(i,2,pos));% ��ȥ����������ʣ��ʱ��

             tmpTranNormal=floor(lastTime*scheRate(i,1,pos)/Normal_L_packet(i));

             % disp(strcat(['rest trans for normal:',num2str(tmpTranNormal)]))

         else

             tmpTranNormal=curNumTranNormal(i);

         end

         curRandForPLRofNormal{m,i}=rand(tmpTranNormal,1); %��ÿһ�η��Ͱ�������һ���������

         for j=1:tmpTranNormal %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ

             %disp(['[Normal:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])

             if queueNormalInfo(m,3,i)<=queueNormalInfo(m,2,i) % �����л��а�Ҫ����

                 %ͳ�Ʒ��Ͱ�����Ϣ

                 packetNormalInfo{i}(end+1,1)=queueNormalInfo(m,3,i);%��õ�ǰ���ڴ���İ���ID���Ҵ��������Ϣ����һ��

                 packetNormalInfo{i}(end,2)=m; %��ǰ֡��������������Ŷ�ʱ��

                 packetNormalInfo{i}(end,3)=curPLRofNormal{m}(i);%PLR 

                 packetNormalInfo{i}(end,4)=schePower(i,1,pos);%P

                 packetNormalInfo{i}(end,5)=Normal_L_packet(i)/scheRate(i,1,pos);%t

                 packetNormalInfo{i}(end,6)=scheRate(i,1,pos);%R

                 if curPLRofNormal{m}(i)<=curRandForPLRofNormal{m,i}(j) %�����ɵ���������ڼ���Ķ��������ʾ���ɹ�����

                     packetNormalInfo{i}(end,7)=1;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                     if i==showNode

                          disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',normalPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),'state: success tran']))

                     end

                     % �԰��Ľ���λ�ý��б�ע

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),4)=Normal_L_packet(i)/scheRate(i,1,pos);  % ״̬λ1��ʾ���ͳɹ�

                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=1;  % ״̬λ1��ʾ���ͳɹ�

                     

                     queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%ָ����һ���� 

                     if (retranFlagN)

                         retranCountN(i)=0; %�ش���������

                     end

                 else

                     % �ж��Ƿ��ش�

                     if (retranFlagN)

                         retranCountN(i)=retranCountN(i)+1; %�ش�������һ

                         if (retranCountN(i)<=retranNorMax(i)) %�ж��ش������Ƿ�С����������

                             packetNormalInfo{i}(end,7)=2; %����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                         else

                             packetNormalInfo{i}(end,7)=3;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                             % �԰��Ľ���λ�ú�״̬λ���б�ע

                             packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;

                             packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=3; %״̬λ3��ʾ�ش�����

                             

                             queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%��ʼ��һ��������

                             retranCountN(i)=0; %�ش���������

                         end

                     else

                         if i==showNode

                             disp(strcat(['nodeInd:',num2str(i),',normal PacketInd:',num2str(queueNormalInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),',state: directly discard']))

                         end

                         packetNormalInfo{i}(end,7)=4;%�ɹ����䣬״̬λΪ1��2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���

                         % �԰��Ľ���λ�ú�״̬λ���б�ע

                         packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;

                         packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=4; %״̬λ4��ֱ�Ӷ���

                         queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;

                     end                 

                 end;                 

             end;             

         end;

     end;

end;



%%��������

resultEnergyNormal=zeros(N_Node,1);

resultEnergyEmergency=zeros(N_Node,1);

%ƽ�������ʣ������ĸ���/�ܷ��Ͱ��ĸ�����

resultPLRofNormal=[];

resultPLRofEmergency=[];

packetDelayNormal=[];

packetDelayEmergency=[];

queueLengthNormal=[];

queueLengthEmergency=[];

DELAYMAX=99999999.0;



for i=1:N_Node

    %% ����ƽ��������

        %��ͨ����ƽ��������:���Է��͵�������index-�ɹ����͵İ�����

        ind1=find(packetNorBeginEnd{i}(:,5)==1);

        ind2=find(packetNorBeginEnd{i}(:,5)>0);

        resultPLRofNormal(i)=(length(ind2)-length(ind1))/length(ind2);

        % ������ 

        ind1=find(packetEmerBeginEnd{i}(:,5)==1);

        ind2=find(packetEmerBeginEnd{i}(:,5)>0);

        resultPLRofEmergency(i)=(length(ind2)-length(ind1))/length(ind2);

    %% ����ʱ�ӣ���ͳ��ÿһ������ƽ��ʱ�ӣ�Ȼ����ͳ���ܵ�ƽ��ʱ�ӡ� ֻ����ɹ�����İ���ʱ��

        % ��ͨ��ʱ��

        for n=1:size(packetNorBeginEnd{i},1)

            if  packetNorBeginEnd{i}(n,5)==1

                packetDelayNormal{i}(n,1)=(packetNorBeginEnd{i}(n,2)-packetNorBeginEnd{i}(n,1))*T_Frame+packetNorBeginEnd{i}(n,3)+packetNorBeginEnd{i}(n,4);

            else

                packetDelayNormal{i}(n,1)=DELAYMAX; %�����û�гɹ����佫������Ϊ�ܴ��ֵ

            end

        end

        ind=find(packetDelayNormal{i}~=DELAYMAX);

        resultNormalAveDelay(i)=mean(packetDelayNormal{i}(ind)); %����ƽ��ʱ��

        resultNormalMaxDelay(i)=max(packetDelayNormal{i}(ind)); %ͳ�����ʱ��

        % ������ʱ��

        for n=1:size(packetEmerBeginEnd{i},1)

            if packetEmerBeginEnd{i}(n,5)==1

                packetDelayEmergency{i}(n,1)=(packetEmerBeginEnd{i}(n,2)-packetEmerBeginEnd{i}(n,1))*T_Frame+packetEmerBeginEnd{i}(n,3)+packetEmerBeginEnd{i}(n,4);

            else

                packetDelayEmergency{i}(n,1)=DELAYMAX; %�����û�д���ɹ�����ͳ�Ƹð���ʱ�ӣ���������Ϊ���ֵ

            end

        end

        ind=find(packetDelayEmergency{i}~=DELAYMAX);

        resultEmergencyAveDelay(i)=mean(packetDelayEmergency{i}(ind)); %����ƽ��ʱ��

        resultEmergencyMaxDelay(i)=max(packetDelayEmergency{i}(ind)); %ͳ�����ʱ��

    %% ͳ�����ܺ�

        % ��ͨ�����ܺ�

        for n=1:packetNormalInfo{i}(end,1)

            ind=find(packetNormalInfo{i}(:,1)==n);

            resultEnergyNormal(i)= resultEnergyNormal(i)+(a+1)*packetNormalInfo{i}(ind,4)'*packetNormalInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetNormalInfo{i}(ind,5);

        end

        % ���������ܺ�

        for n=1:packetEmergencyInfo{i}(end,1)

            ind=find(packetEmergencyInfo{i}(:,1)==n);

            resultEnergyEmergency(i)= resultEnergyEmergency(i)+(a+1)*packetEmergencyInfo{i}(ind,4)'*packetEmergencyInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetEmergencyInfo{i}(ind,5);

        end

    

     %% ͳ�ƶ�����ÿһ֡��ʼ�ͷ��ͽ���ʱ�İ���

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

    %������

    save(strcat(PLRInfo,'_finalResult0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'result*','packetDelayNormal','packetDelayEmergency')

    save(strcat(PLRInfo,'_shadow_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'X_Shadow_Real')

    save(strcat(PLRInfo,'_numPacket_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'curNumNormalPacket','curNumEmergencyPacket')

    save(strcat(PLRInfo,'_all0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))







