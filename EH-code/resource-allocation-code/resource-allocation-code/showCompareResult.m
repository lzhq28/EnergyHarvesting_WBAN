%% չʾ�ԱȽ��
function [showCompareNormalResult, showCompareEmergencyResult]=showCompareResult(noiseIndex,deltaPLIndex,deltaPL,PNoise,showCompareNormalResult,showCompareEmergencyResult)
%����


%���ع̶����ʵ�ʵ����

showFigure=0;

load(strcat('finalResult1_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))

showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,1)=resultEnergyNormal;%����
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,1)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,1)=resultPLRofNormal';%������
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,1)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,1)=resultNormalAveDelay';%ʱ��
showCompareEmergencyResult{noiseIndex,deltaPLIndex,3}(:,1)=resultEmergencyAveDelay';

%����TPC��ʵ����
clear resultEnergyNormal resultEnergyEmergency resultPLRofNormal resultPLRofEmergency resultNormalMaxDelay resultEmergencyMaxDelay
load(strcat('finalResult2_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,2)=resultEnergyNormal;%����
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,2)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,2)=resultPLRofNormal';%������
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,2)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,2)=resultNormalAveDelay';%ʱ��
showCompareEmergencyResult{noiseIndex,deltaPLIndex,3}(:,2)=resultEmergencyAveDelay';

%���ر��ʷ�����ʵ����

clear resultEnergyNormal resultEnergyEmergency resultPLRofNormal resultPLRofEmergency resultNormalMaxDelay resultEmergencyMaxDelay
load(strcat('finalResult0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
showCompareNormalResult{noiseIndex,deltaPLIndex,1}(:,3)=resultEnergyNormal;%����
showCompareEmergencyResult{noiseIndex,deltaPLIndex,1}(:,3)=resultEnergyEmergency;
showCompareNormalResult{noiseIndex,deltaPLIndex,2}(:,3)=resultPLRofNormal';%������
showCompareEmergencyResult{noiseIndex,deltaPLIndex,2}(:,3)=resultPLRofEmergency';
showCompareNormalResult{noiseIndex,deltaPLIndex,3}(:,3)=resultNormalAveDelay';%ʱ��
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

