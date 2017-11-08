%% 展示对比结果
function [showCompareNormalResult, showCompareEmergencyResult]=showCompareResult(noiseIndex,deltaPLIndex,deltaPL,PNoise,showCompareNormalResult,showCompareEmergencyResult)
%输入


%加载固定功率的实验结果

showFigure=0;

load(strcat('finalResult1_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))

showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,1)=resultEnergyNormal;%能量
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,1)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,1)=resultPLRofNormal';%丢包率
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,1)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,1)=resultNormalAveDelay';%时延
showCompareEmergencyResult{noiseIndex,deltaPLIndex,3}(:,1)=resultEmergencyAveDelay';

%加载TPC的实验结果
clear resultEnergyNormal resultEnergyEmergency resultPLRofNormal resultPLRofEmergency resultNormalMaxDelay resultEmergencyMaxDelay
load(strcat('finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,2)=resultEnergyNormal;%能量
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,2)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,2)=resultPLRofNormal';%丢包率
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,2)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,2)=resultNormalAveDelay';%时延
showCompareEmergencyResult{noiseIndex,deltaPLIndex,3}(:,2)=resultEmergencyAveDelay';

%加载本问方法的实验结果

clear resultEnergyNormal resultEnergyEmergency resultPLRofNormal resultPLRofEmergency resultNormalMaxDelay resultEmergencyMaxDelay
load(strcat('finalResult0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,3)=resultEnergyNormal;%能量
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,3)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,3)=resultPLRofNormal';%丢包率
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,3)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,3)=resultNormalAveDelay';%时延
showCompareEmergencyResult{noiseIndex,deltaPLIndex,3}(:,3)=resultEmergencyAveDelay';

if showFigure==1
    %compare energy 
    figure(1)
    subplot(121)
    bar( showCompareNormalResult{noiseIndex,deltaPLIndex,1})
    xlabel('Different Nodes')
    ylabel('Energy consume(uJ)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
    title('Energy consume for normal packet transmission')
    
    subplot(122)
    bar( showCompareEmergencyResult{noiseIndex,deltaPLIndex,1})
    title('Energy consume for emergency packet transmission')
    xlabel('Different Nodes')
    ylabel('Energy consume(uJ)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
     

   %compare PLR
    figure(2)
    subplot(121)
    bar( 100*showCompareNormalResult{noiseIndex,deltaPLIndex,2})
    title('PLR for normal packet transmission')
    xlabel('Different Nodes')
    ylabel('Packet Loss Rate(%)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
     
    
    subplot(122)
    bar( 100*showCompareEmergencyResult{noiseIndex,deltaPLIndex,2})
    title('PLR for emergency packet transmission')
    xlabel('Different Nodes')
    ylabel('Packet Loss Rate(%)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
    
    %compare Delay
    figure(3)
    subplot(121)
    bar( showCompareNormalResult{noiseIndex,deltaPLIndex,3})
    title('Delay for normal packet transmission')
    xlabel('Different Nodes')
    ylabel('Delay of the Packet(ms)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
    
    subplot(122)
    bar( showCompareEmergencyResult{noiseIndex,deltaPLIndex,3})
    title('Delay for emergency packet transmission')
    xlabel('Different Nodes')
    ylabel('Delay of the Packet(ms)')
    legend('Decide','TPC','Optimal','Location','NorthWest')
    set(gca, 'XTick',[1 2 3 4 5])
    set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
    
end;

