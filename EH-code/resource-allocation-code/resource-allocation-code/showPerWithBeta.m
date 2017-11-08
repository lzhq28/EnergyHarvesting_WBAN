clc
clear all
format short
load('./data/miuThNode0.3-0.275-0.25-0.225-0.2-0.175-0.15-0.125-0.1-0.075-0.05-0.025-0.01-0.005.mat')
[X_Shadow_Real,curNumNormalPacket,curNumEmergencyPacket,posSeries]=shadowAndNumPacketPerFrame(0)
configureChannelPar
rateAllocationFlag=1;%表示采用速率分配策略
for PLRIndex=size(avePLRSet,2)-1 :size(avePLRSet,2)-1     
    avePLRth=[avePLRSet(PLRIndex),avePLRSet(PLRIndex+1)] %每次紧急包的丢包率门限都要下于正常包
    for n=1:N_Node
        for pos=1:posNum        
           miuTh(2*(pos-1)+1,n)= miuThNode{n,pos}(1,PLRIndex); %正常包
           miuTh(2*pos,n)= miuThNode{n,pos}(2,PLRIndex+1); %正常包       
        end
    end;
    %%在对正常包和紧急的门限设置时，紧急包的门限都要低于正常包
    %channelPar(PNoise,deltaPL,miuTh,avePLRth)
    
    for mm=1:1:10
        deltaT=mm*0.1
        [PLRN{PLRIndex,mm},PLRE{PLRIndex,mm},EnergyN{PLRIndex,mm},EnergyE{PLRIndex,mm}, DelayN{PLRIndex,mm},DelayE{PLRIndex,mm}]=performance(PNoise,deltaPL,miuTh,avePLRth,rateAllocationFlag,deltaT);             
        DeltaPLRNor(mm)=mean(PLRN{PLRIndex,mm})
        DeltaEnergyNor(mm)=sum(EnergyN{PLRIndex,mm})
    end;
end;
%save('delatTPER.mat')
%load('delatTPER.mat')
format long 
figure(1)
subplot(121)
plot(0.2:0.1:1,100*DeltaPLRNor(2:end),'-o','linewidth',2)
grid on
xlabel('Value of \beta')
ylabel('Attainable Average PLR(%)')
title('Normal Packets Transmission ')
subplot(122)
plot(DeltaEnergyNor(2:end),'-o','linewidth',2)
grid on
xlabel('Value of \beta')
ylabel('Energy Consumption (uJ)')
title('Normal Packets Transmission')
 
 