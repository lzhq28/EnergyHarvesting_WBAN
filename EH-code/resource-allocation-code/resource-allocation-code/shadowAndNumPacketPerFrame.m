%% �����ŵ��������ò�����Ӧ����Ӱ˥���ÿһ֡�ڵİ��ĵ������
function [X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(reCalculate)
    configureChannelPar
    shadowAndNumPacketPATH=strcat(['./data/shadowAndNumPacket_Nch-',num2str(N_ch),'.mat']);
    if((reCalculate)||(exist(shadowAndNumPacketPATH,'file')~=2)) % һ���һ�ν������¼��㣬���Ҫ�����ظ����鲻��Ҫ�������¼���
        disp('����shadowAndNumPacketPerFrame��ʾ�����¼������ݡ�')
        posSeries=[];
        for m=1:N_ch
             if m<= probPosture(1)*N_ch
                 pos=1;           
             elseif m<=(probPosture(1)+probPosture(2))*N_ch
                 pos=2;
             else
                 pos=3;
             end;
             posSeries(m)=pos;
             X_Shadow_Real{m}=(NodeKese(pos,:)'.*randn(N_Node,1,'double')); 
             curNumNormalPacket(m,:)=numNormalPacket;
             curNumEmergencyPacket(m,:)=poissrnd(numEmergencyPacket); 
        end;
        save(shadowAndNumPacketPATH)       
    else
        disp('����shadowAndNumPacketPerFrame��ʾ�������ļ����ڽ�ֱ�Ӽ��ػ�á�')
        load(shadowAndNumPacketPATH)
    end
   



  

 