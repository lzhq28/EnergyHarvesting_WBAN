function []=compareTPC(PNoise,deltaPL,T_L,T_H)
PLRInfo='./data/PLRN0.01E0.005'
load(strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_shadow_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_numPacket_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat(PLRInfo,'_optimalValue_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
probPosture=[0.5 0.3 0.2]; %��ͬ����״̬�µ���̬����
packetNormalInfo=[];
packetEmergencyInfo=[];
packetNormalInfo{N_Node}=[];  %ͳ�ư�����Ϣ ��ʽ�� ID �� cur Nch�� PLR ��P ��t, R
packetEmergencyInfo{N_Node}=[]; 
curRandForPLRofNormal=[];
curRandForPLRofEmergency=[];
packetDelay=[]; %ͳ��ÿ���ڵ㷢�͵�ÿ�����Ķ������
packetDelay{N_Node}=[];

countNormalPacket=zeros(1,N_Node);
countEmergencyPacket=zeros(1,N_Node);

%% ѭ��-
    % ���в�������
    priorityTranFlag=1 %�Ƿ������ռʽ���ȼ��ŶӲ��ԣ�������ã������ȷ��ͽ�������ֻ�н��������ͽ��պ��ٷ�����ͨ��
    retranFlag=0
    showNode=1 ;% Ҫչʾ��Ϣ�Ľڵ㣬Ϊ0��ʾ����ʾ
    retranCountN=zeros(1,N_Node);
    retranCountE=zeros(1,N_Node);
    retranNorMax=repmat([4],1,N_Node);     % ������ͨ��������ش�����
    retranEmerMax=repmat([4],1,N_Node);     % ���ý�����������ش�����
    queueNorMax=repmat([25],1,N_Node);  % ������ͨ���������г���
    queueEmerMax=repmat([25],1,N_Node);     % ���ý������������г���
    packetNorBeginEnd{N_Node}=[];   % ���ݰ��Ŀ�ʼ�ͽ���֡λ��
    packetEmerBeginEnd{N_Node}=[];  % �������Ŀ�ʼ�ͽ���λ��
    
for m=1:N_ch
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%�����ǶԱ��������Ҫ����%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %��������
    a_d=0.8;
    a_u=0.6;
%     T_L=-63;%-65ʱϵͳ���ܻ�����
%     T_H=-53;%-55ʱ���ܲ���
    %�����ŵ���Ϣ������Դ������һ��ֻ�Թ��ʽ�������
    decideFlag=1; %Ϊ1ʱ��ʾʹ�ù̶�����
    if decideFlag==1
            if m<= probPosture(1)*N_ch
                %���ù̶�����������
                scheRate(1:N_Node,1,m)=DataRate(4);  
                scheRate(1:N_Node,2,m)=DataRate(4);  
            elseif m<=(probPosture(1)+probPosture(2))*N_ch 
              %���ù̶�����������
                 scheRate(1:N_Node,1,m)=DataRate(4);  
                 scheRate(1:N_Node,2,m)=DataRate(4); 
            else
                   %���ù̶�����������
                 scheRate(1:N_Node,1,m)=DataRate(4);  
                 scheRate(1:N_Node,2,m)=DataRate(4); 
            end;
    else
                if m<= probPosture(1)*N_ch
                %��������ȷ�����ԵĽ��
                    scheRate(1:N_Node,1,m)=posRate{1}(1:2:end,1);  
                    scheRate(1:N_Node,2,m)=posRate{1}(2:2:end,1);    
                elseif m<=(probPosture(1)+probPosture(2))*N_ch
                     %��������ȷ�����ԵĽ��
                     scheRate(1:N_Node,1,m)=posRate{2}(1:2:end,1); 
                     scheRate(1:N_Node,2,m)=posRate{2}(2:2:end,1); 
                else
                    %��������ȷ�����ԵĽ��
                     scheRate(1:N_Node,1,m)=posRate{3}(1:2:end,1);  
                     scheRate(1:N_Node,2,m)=posRate{3}(2:2:end,1);  
                end;
    end;
 
     scheTime(:,1,m)=ceil(numNormalPacket'.*Normal_L_packet'./scheRate(1:N_Node,1,m)./T_Slot).*T_Slot;%Normal_SourceRate.*T_Frame./scheRate(:,1,m);%����������Ҫ��
     scheTime(:,2,m)=ceil(numEmergencyPacket'.*Emergency_L_packet'./scheRate(1:N_Node,2,m)./T_Slot).*T_Slot;% Emergency_SourceRate_Ave.*T_Frame./scheRate(:,2,m);%����������Ҫ��
     
     if sum(sum(scheTime(:,:,m)))>T_Frame
          disp(['warnning in compareTPC: sum(t)=',num2str( sum(sum(scheTime(:,:,m)))),'>T_Frame '])
     end;
     if m==1
         schePower(:,1,m)=ones(N_Node,1);%��ʼ��Ϊ1mW
         schePower(:,2,m)=ones(N_Node,1);%��ʼ��Ϊ1mW
         schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%���ʣ�dBΪ��λ
         schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
         aveRSSINormal(1:N_Node,1)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
         aveRSSIEmergency(1:N_Node,1)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
     else
         schePower(:,1,m)=schePower(:,1,m-1);
         schePower(:,2,m)=schePower(:,2,m-1);
         schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%���ʣ�dBΪ��λ
         schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
         curRSSINormal(1:N_Node,m)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
         curRSSIEmergency(1:N_Node,m)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
         
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
             schePower(index5,1,m)=schePower(index5,1,m).*2;%���ʼӱ�
             index6=find(schePower(:,1,m)>P_tx_max);
             if ~isempty(index6)
                 schePower(index6,1,m)=P_tx_max;
             end;
         end;
         index5=find(aveRSSIEmergency<T_L);
         if size(index5,1)~=0
             schePower(index5,2,m)=schePower(index5,2,m).*2;%���ʼӱ�
             index6=find(schePower(:,2,m)>P_tx_max);
             if ~isempty(index6)
                 schePower(index6,2,m)=P_tx_max;
             end;
         end;
         
         index7=find(aveRSSINormal>T_H);
         if ~isempty(index7)
             schePower(index7,1,m)=schePower(index7,1,m)./2;%���ʼӱ�
             index8=find(schePower(:,1,m)<P_tx_min);
             if ~isempty(index8)
                 schePower(index8,1,m)=P_tx_min;
             end;             
         end;
         index7=find(aveRSSIEmergency>T_H);
         if ~isempty(index7)
             schePower(index7,2,m)=schePower(index7,2,m)./2;%���ʼӱ�
             index8=find(schePower(:,2,m)<P_tx_min);
             if ~isempty(index8)
                 schePower(index8,2,m)=P_tx_min;
             end;             
         end; 
     end;
     schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%���ʣ�dBΪ��λ
     schePowerDB(:,2,m)=10*log10(schePower(:,2,m));
 


     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %���������
     for i=1:N_Node
         countNormalPacket(1,i)=countNormalPacket(1,i)+curNumNormalPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�
         countEmergencyPacket(1,i)=countEmergencyPacket(1,i)+curNumEmergencyPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�
         if m==1  %��һ������У���ʼ������
             queueNormalInfo(m,1,i)=1;
             queueNormalInfo(m,2,i)=countNormalPacket(1,i);
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);
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
             queueNormalInfo(m,1,i)=queueNormalInfo(m-1,3,i); %��һ֡�����͵�λ��Ϊ��ǰ֡�ڶ��еĿ�ʼλ��
             queueNormalInfo(m,2,i)=countNormalPacket(1,i); 
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);  
             % ��¼���ݰ��Ŀ�ʼ��ֵλ�úͽ���λ�ã��ڿ�ʼ��֡ǰ�ȴ���ʱ��
             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),1)=m; %��¼��ͨ���Ŀ�ʼ֡λ��
             packetNorBeginEnd{i}(queueNormalInfo(m-1,2,i)+1:queueNormalInfo(m,2,i),3)=T_Frame*(1:curNumNormalPacket(m,i))./(curNumNormalPacket(m,i)+1);
             % �ж���ͨ�������Ƿ����
             if  queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1>queueNorMax(i) %������г��ȴ�����󻺴泤�Ƚ����ж���
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
    
    curNumTranNormal=floor(scheTime(:,1,m).*scheRate(:,1,m)./Normal_L_packet');%�����ʱ϶���Է��Ͱ��Ĵ���
    curNumTranEmergency=floor(scheTime(:,2,m).*scheRate(:,2,m)./Emergency_L_packet');%�����ʱ϶���Է��Ͱ��Ĵ���
    allNumTranEmergency=floor((scheTime(:,1,m)+scheTime(:,2,m)).*scheRate(:,2,m)./Emergency_L_packet');

    % ��ʼ���䣬����Ϊ��1�������ش���2���������ش���3��������������ռʽ���ȼ�
       for i=1:N_Node
           %����������
         if  priorityTranFlag %��������ռʽ
             tmpTranEmergency = allNumTranEmergency(i);
             tmpCursor=0;
         else
             tmpTranEmergency = curNumTranEmergency(i);
         end;
           %����������
         curRandForPLRofEmergency{m,i}=rand(tmpTranEmergency,1); %��ÿһ�η��Ͱ�������һ���������
         for j=1:tmpTranEmergency %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ
            % disp(['[Emergency:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])
             if queueEmergencyInfo(m,3,i)<=queueEmergencyInfo(m,2,i) %�����л��а�Ҫ����
                 %ͳ�Ʒ��Ͱ�����Ϣ
                packetEmergencyInfo{i}(end+1,1)=queueEmergencyInfo(m,3,i);%��õ�ǰ���ڴ���İ���ID���Ҵ��������Ϣ����һ��
                packetEmergencyInfo{i}(end,2)=m; %��ǰ֡��������������Ŷ�ʱ��
                packetEmergencyInfo{i}(end,3)=curPLRofEmergency{m}(i);%PLR 
                if m==1
                    packetEmergencyInfo{i}(end,4)=schePower(i,2,m);%P
                else
                    packetEmergencyInfo{i}(end,4)=schePower(i,2,m-1);%P
                end;
                packetEmergencyInfo{i}(end,5)=Emergency_L_packet(i)/scheRate(i,2,m);%t
                packetEmergencyInfo{i}(end,6)=scheRate(i,2,m);%R
                 if curPLRofEmergency{m}(i)<=curRandForPLRofEmergency{m,i}(j) %�����ɵ���������ڼ���Ķ��������ʾ���ɹ�����
                     packetEmergencyInfo{i}(end,7)=1;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���
                     if i==showNode
                        disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',emergencyPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountE(i)),'state: success tran']))
                     end
                     % �԰�����λ�ý���
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),2)=m;
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),4)=Emergency_L_packet(i)/scheRate(i,2,m);
                     packetEmerBeginEnd{i}(queueEmergencyInfo(m,3,i),5)=1;
                     
                     queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;%ָ����һ����
                     if(retranFlag)
                         retranCountE(i)=0; %�ش���������
                     end
                 else
                      %�ж��Ƿ��ش�
                     if (retranFlag) %����ش�
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
             lastTime=((scheTime(i,1,m)+scheTime(i,2,m))-(tmpCursor-1)*Emergency_L_packet(i)/scheRate(i,2,m));% ��ȥ����������ʣ��ʱ��
             tmpTranNormal=floor(lastTime*scheRate(i,1,m)/Normal_L_packet(i));
             disp(strcat(['rest trans for normal:',num2str(tmpTranNormal)]))
         else
             tmpTranNormal=curNumTranNormal(i);
         end
         curRandForPLRofNormal{m,i}=rand(tmpTranNormal,1); %��ÿһ�η��Ͱ�������һ���������
         for j=1:tmpTranNormal %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ
             %disp(['[Normal:NCh,Node,Times:]',num2str(m),',',num2str(i),',',num2str(j)])
             if queueNormalInfo(m,3,i)<=queueNormalInfo(m,2,i) %�����л��а�Ҫ����
                 %ͳ�Ʒ��Ͱ�����Ϣ
                 packetNormalInfo{i}(end+1,1)=queueNormalInfo(m,3,i);%��õ�ǰ���ڴ���İ���ID���Ҵ��������Ϣ����һ��
                 packetNormalInfo{i}(end,2)=m; %��ǰ֡��������������Ŷ�ʱ��
                 packetNormalInfo{i}(end,3)=curPLRofNormal{m}(i);%PLR 
                
                 if m==1
                      packetNormalInfo{i}(end,4)=schePower(i,1,m);%P
                 else
                      packetNormalInfo{i}(end,4)=schePower(i,1,m-1);%P
                 end;
                 packetNormalInfo{i}(end,5)=Normal_L_packet(i)/scheRate(i,1,m);%t
                 packetNormalInfo{i}(end,6)=scheRate(i,1,m);%R
                 if curPLRofNormal{m}(i)<=curRandForPLRofNormal{m,i}(j) %�����ɵ���������ڼ���Ķ��������ʾ���ɹ�����
                     packetNormalInfo{i}(end,7)=1;%����״̬λ��1��ʾ����ɹ���2��ʾ�ش�,3��ʾ�ش����޶�����4��ʾֱ�Ӷ���
                     if i==showNode
                          disp(strcat(['rest tran times:',num2str(j),',nodeInd:',num2str(i),',normalPacketInd:',num2str(queueEmergencyInfo(m,3,i)),',retranNum:',num2str(retranCountN(i)),'state: success tran']))
                     end
                     % �԰��Ľ���λ�ý��б�ע
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),2)=m;
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),4)=Normal_L_packet(i)/scheRate(i,1,m);  % ״̬λ1��ʾ���ͳɹ�
                     packetNorBeginEnd{i}(queueNormalInfo(m,3,i),5)=1;  % ״̬λ1��ʾ���ͳɹ�

                     queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%ָ����һ����     
                     if (retranFlag)
                         retranCountN(i) = 0; %�ش���������
                     end
                 else
                    % �ж��Ƿ��ش�
                     if (retranFlag)
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
% %%��������
resultEnergyNormal=zeros(N_Node,1);
resultEnergyEmergency=zeros(N_Node,1);
% %ƽ�������ʣ������ĸ���/�ܷ��Ͱ��ĸ�����
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
    
     %ͳ�ƶ�����ÿһ֡��ʼ�ͷ��ͽ���ʱ�İ���
     for m=1:size(queueNormalInfo,1)      
         queueLengthNormal(m,1,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1;
         queueLengthNormal(m,2,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,3,i)+1; 
         queueLengthEmergency(m,1,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1;
         queueLengthEmergency(m,2,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,3,i)+1;
     end;
end;
TPCInfo=strcat('./data/TPC_TL',num2str(T_L),'_TH',num2str(T_H))
save(strcat(TPCInfo,'_all2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'));%�������е�����
save(strcat(TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'result*','packetDelayNormal','packetDelayEmergency');