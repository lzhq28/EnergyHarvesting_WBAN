%�Ա����飺LSE-TPC�����¡�Link-State-Estimation-Based Transmission Power Control in Wireless Body Area Networks��
function []=compareLSE_TPC(PNoise,deltaPL,T_L,T_H)
PLRInfo='PLRN0.01E0.005'
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
countN=10; %����֡����һ���޸Ĺ���
countNormalPacket=zeros(1,N_Node);
countEmergencyPacket=zeros(1,N_Node);

for m=1:N_ch
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%�����ǶԱ��������Ҫ����%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %��������
 
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
     
     %��ʼ������Ϊ���ֵ
     if m<=5*countN
         schePower(:,1,m)=ones(N_Node,1);%��ʼ��Ϊ1mW
         schePower(:,2,m)=ones(N_Node,1);%��ʼ��Ϊ1mW
         schePowerDB(:,1,m)=10*log10(schePower(:,1,m));%���ʣ�dBΪ��λ
         schePowerDB(:,2,m)=10*log10(schePower(:,2,m));           
     else
         schePowerDB(:,1,m)=schePowerDB(:,1,m-1)+E_link_nor;
         schePowerDB(:,2,m)=schePowerDB(:,2,m-1)+E_link_emer;      
         
         schePowerDB(schePowerDB(:,1,m)>P_tx_max_dBm,1,m)=P_tx_max_dBm;
         schePowerDB(schePowerDB(:,1,m)<P_tx_min_dBm,1,m)=P_tx_min_dBm;
         schePowerDB(schePowerDB(:,2,m)>P_tx_max_dBm,2,m)=P_tx_max_dBm;
         schePowerDB(schePowerDB(:,2,m)<P_tx_min_dBm,2,m)=P_tx_min_dBm;
      
          
         schePower(:,1,m)=power(10,0.1*schePowerDB(:,1,m));
         schePower(:,2,m)=power(10,0.1*schePowerDB(:,2,m));
         
     end;
     
     
 
     
     R2_nor(:,rem(m,5*countN)+1)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};
     R2_emer(:,rem(m,5*countN)+1)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};
     
     
     R_nor(:,rem(m,countN)+1)=schePowerDB(:,1,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
     R_emer(:,rem(m,countN)+1)=schePowerDB(:,2,m)-NoPL'-X_Shadow_Real{m};% �������Ӱ˥�����Լ������ʵ�����Ӱ˥��ֵ
     
      
     h_nor(:,rem(m,countN)+1)=R_nor(:,rem(m,countN)+1);      
     h_nor( h_nor(:,rem(m,countN)+1)<=T_H,rem(m,countN)+1)=T_H;
     h_emer(:,rem(m,countN)+1)=R_emer(:,rem(m,countN)+1);
     h_emer(h_emer(:,rem(m,countN)+1)<=T_H,rem(m,countN)+1)=T_H;
      
     l_nor(:,rem(m,countN)+1)=R_nor(:,rem(m,countN)+1); 
     l_nor(l_nor(:,rem(m,countN)+1)>=T_L,rem(m,countN)+1)=T_L;
     l_emer(:,rem(m,countN)+1)=R_emer(:,rem(m,countN)+1);
     l_emer(l_emer(:,rem(m,countN)+1)>=T_L,rem(m,countN)+1)=T_L;
     
     E_link_nor=mean(T_H-h_nor,2)+mean(T_L-l_nor,2);
     E_link_emer=mean(T_H-h_emer,2)+mean(T_L-l_emer,2);
    
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %���������
     for i=1:N_Node
         countNormalPacket(1,i)=countNormalPacket(1,i)+curNumNormalPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�
         countEmergencyPacket(1,i)=countEmergencyPacket(1,i)+curNumEmergencyPacket(m,i);%ͳ�ƽڵ㹲�������ٰ�
         if m==1  %��һ������У���ʼ������
             queueNormalInfo(m,1,i)=1;
             queueNormalInfo(m,2,i)=countNormalPacket(1,i);
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);
             
             queueEmergencyInfo(m,1,i)=1;
             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);
             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);
             
         else
             queueNormalInfo(m,1,i)=queueNormalInfo(m-1,3,i); %��һ֡�����͵�λ��Ϊ��ǰ֡�ڶ��еĿ�ʼλ��
             queueNormalInfo(m,2,i)=countNormalPacket(1,i); 
             queueNormalInfo(m,3,i)=queueNormalInfo(m,1,i);  
             
             queueEmergencyInfo(m,1,i)=queueEmergencyInfo(m-1,3,i);
             queueEmergencyInfo(m,2,i)=countEmergencyPacket(1,i);
             queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,1,i);
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

       for i=1:N_Node
         %����������
         curRandForPLRofNormal{m,i}=rand(curNumTranNormal(i),1); %��ÿһ�η��Ͱ�������һ���������
         for j=1:curNumTranNormal(i) %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ
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
                     queueNormalInfo(m,3,i)=queueNormalInfo(m,3,i)+1;%ָ����һ����                    
                 else
                     %�����ʾ��������ǰ��ָ�벻������                     
                 end;                 
             end;             
         end;
         %����������
         curRandForPLRofEmergency{m,i}=rand(curNumTranEmergency(i),1); %��ÿһ�η��Ͱ�������һ���������
         for j=1:curNumTranEmergency(i) %������Ͱ���ͳ�Ʒ��Ͱ�����Ϣ
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
                     queueEmergencyInfo(m,3,i)=queueEmergencyInfo(m,3,i)+1;%ָ����һ����
                 else
                     %�����ʾ��������ǰ��ָ�벻������                     
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
for i=1:N_Node
    %ƽ��������
    resultPLRofNormal(i)=(size(packetNormalInfo{i},1)-packetNormalInfo{i}(end,1))/size(packetNormalInfo{i},1);
    resultPLRofEmergency(i)=(size(packetEmergencyInfo{i},1)-packetEmergencyInfo{i}(end,1))/size(packetEmergencyInfo{i},1);
    
    %����ʱ�ӣ���ͳ��ÿһ������ƽ��ʱ�ӣ�Ȼ����ͳ���ܵ�ƽ��ʱ��
    %������
    for n=1:packetNormalInfo{i}(end,1) %ͳ��ÿһ������ʱ��
        ind=find(packetNormalInfo{i}(:,1)==n);
        packetDelayNormal{i}(n,1)=(packetNormalInfo{i}(ind(end),2)-packetNormalInfo{i}(ind(1),2))*T_Frame+0.5*T_Frame;
        %�������ܺ�
       resultEnergyNormal(i)= resultEnergyNormal(i)+(a+1)*packetNormalInfo{i}(ind,4)'*packetNormalInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetNormalInfo{i}(ind,5);
    end;
    %������
    for n=1:packetEmergencyInfo{i}(end,1)
        ind=find(packetEmergencyInfo{i}(:,1)==n);
        packetDelayEmergency{i}(n,1)=(packetEmergencyInfo{i}(ind(end),2)-packetEmergencyInfo{i}(ind(1),2))*T_Frame+0.5*T_Frame;
        %�������ܺ�
       resultEnergyEmergency(i)= resultEnergyEmergency(i)+(a+1)*packetEmergencyInfo{i}(ind,4)'*packetEmergencyInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetEmergencyInfo{i}(ind,5);
    end;
     %ͳ�ƶ�����ÿһ֡��ʼ�ͷ��ͽ���ʱ�İ���
     for m=1:size(queueNormalInfo,1)      
         queueLengthNormal(m,1,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,1,i)+1;
         queueLengthNormal(m,2,i)=queueNormalInfo(m,2,i)-queueNormalInfo(m,3,i)+1; 
         queueLengthEmergency(m,1,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,1,i)+1;
         queueLengthEmergency(m,2,i)=queueEmergencyInfo(m,2,i)-queueEmergencyInfo(m,3,i)+1;
     end;
     resultNormalAveDelay(i)=mean(packetDelayNormal{i});     
     resultEmergencyAveDelay(i)=mean(packetDelayEmergency{i});
     resultNormalMaxDelay(i)=max(packetDelayNormal{i});
     resultEmergencyMaxDelay(i)=max(packetDelayEmergency{i});
end;
LSE_TPCInfo=strcat('LSE_TPC_TL',num2str(T_L),'_TH',num2str(T_H))
save(strcat(LSE_TPCInfo,'_all2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'));%�������е�����
save(strcat(LSE_TPCInfo,'_finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'),'result*','packetDelayNormal','packetDelayEmergency');