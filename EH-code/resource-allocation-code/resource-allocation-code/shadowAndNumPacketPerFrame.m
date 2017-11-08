%% 根据信道参数配置产生相应的阴影衰落和每一帧内的包的到达情况
function [X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(reCalculate)
    configureChannelPar
    shadowAndNumPacketPATH=strcat(['./data/shadowAndNumPacket_Nch-',num2str(N_ch),'.mat']);
    if((reCalculate)||(exist(shadowAndNumPacketPATH,'file')~=2)) % 一般第一次进行重新计算，如果要进行重复试验不需要进行重新计算
        disp('函数shadowAndNumPacketPerFrame提示：重新计算数据。')
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
        disp('函数shadowAndNumPacketPerFrame提示：数据文件存在将直接加载获得。')
        load(shadowAndNumPacketPATH)
    end
   



  

 