%% 观察系统性能随噪声的增加的变化情况

clc
clear all
format short
showCompareNormalResult=[];
showCompareEmergencyResult=[];
stepPNoise=1;%PNoise递减的步长
ver=13;%版本号
stepDeltaPL=2;%通过增加路径损耗来观察实验结果
deltaPLMaxIndex=41;
noiseMaxIndex=1;
 
for deltaPLIndex=1:deltaPLMaxIndex
    for noiseIndex=1:1%noiseMaxIndex
        disp(['&&&&&&&&&&&&进度：',num2str(deltaPLIndex),['/'],num2str(deltaPLMaxIndex),['&&&&&&&&&&&&&&&&&']])
         
        deltaPL=(deltaPLIndex-1)*stepDeltaPL;%增加的路径损耗值
        %% 计算参数
        channelPar(PNoise,deltaPL)
        %% 本算法的计算
        performance(PNoise,deltaPL)
        %固定速率方法
        disp(['*************decide***************'])
        compareDecide(PNoise,deltaPL)
        %TPC方法
        disp(['*************TPC***************'])
        compareTPC(PNoise,deltaPL)
        [showCompareNormalResult, showCompareEmergencyResult]=showCompareResult(noiseIndex,deltaPLIndex,deltaPL,PNoise,showCompareNormalResult,showCompareEmergencyResult);

    end;
end;

%分别针对节点进行统计
N_Node=5;
showResult=0;
for i=1:N_Node
    for n=1:1%noiseMaxIndex
        for m=1:deltaPLMaxIndex
            compareNormalEnergyByNode{i,n}(m,:)=showCompareNormalResult{n,m,1}(i,:); 
            compareNormalPLRByNode{i,n}(m,:)=showCompareNormalResult{n,m,2}(i,:);
            compareNormalDelayByNode{i,n}(m,:)=showCompareNormalResult{n,m,3}(i,:);

            compareEmergencyEnergyByNode{i,n}(m,:)=showCompareEmergencyResult{n,m,1}(i,:); 
            compareEmergencyPLRByNode{i,n}(m,:)=showCompareEmergencyResult{n,m,2}(i,:);
            compareEmergencyDelayByNode{i,n}(m,:)=showCompareEmergencyResult{n,m,3}(i,:);
        end;
    end;
end;

%对所有节点系能进行求平均，而能耗采用总能耗的方式
for n=1:1%noiseMaxIndex
    for m=1:deltaPLMaxIndex
        compareNormalEnergySumNode(m,:,n)=sum(showCompareNormalResult{n,m,1});
        compareNormalPLRMeanNode(m,:,n)=mean(showCompareNormalResult{n,m,2});
        compareNormalPLRStandardNode(m,:,n)=std(showCompareNormalResult{n,m,2});
        compareNormalDelayMeanNode(m,:,n)=mean(showCompareNormalResult{n,m,3});
        
        
        compareEmergencyEnergySumNode(m,:,n)=sum(showCompareEmergencyResult{n,m,1});
        compareEmergencyPLRMeanNode(m,:,n)=mean(showCompareEmergencyResult{n,m,2});
        compareEmergencyPLRStandardNode(m,:,n)=std(showCompareEmergencyResult{n,m,2});
        compareEmergencyDelayMeanNode(m,:,n)=mean(showCompareEmergencyResult{n,m,3});
        
    end;
end;
save(strcat('showFinal','-v',num2str(ver),'.mat'))

showResult=1
if showResult==1
%% 显示正常包结果
%% 平均能耗
    noiseShowIndex=1;%显示资源状态
    PNoise=-94;    
    figure(1)
    subplot(121)
    plot(compareNormalEnergySumNode(:,1,noiseShowIndex),'-ro','LineWidth',2)
    hold on
    plot(compareNormalEnergySumNode(:,2,noiseShowIndex),'-co','LineWidth',2)
    hold on
    plot(compareNormalEnergySumNode(:,3,noiseShowIndex),'-bo','LineWidth',2)
    title('Total Energy Consume of Normal Packet Transmission   ')
    xlabel('Quantity of increasing Path Loss(dB)')
    ylabel('Total Energy Consume(uJ)')
    set(gca,'XTick',1:4:deltaPLMaxIndex)
    %set(gca,'YTick',0:100000:1200000) 
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal')
    subplot(122)
    plot(compareEmergencyEnergySumNode(:,1,noiseShowIndex),'-ro','LineWidth',2)
    hold on
    plot(compareEmergencyEnergySumNode(:,2,noiseShowIndex),'-co','LineWidth',2)
    hold on
    plot(compareEmergencyEnergySumNode(:,3,noiseShowIndex),'-bo','LineWidth',2)
    title('Total Energy Consume of Emergency Packet Transmission ')    
    ylabel('Total Energy Consume(uJ)')
    xlabel('Quantity of increasing Path Loss(dB)')
    %axis([1 15 0 max(max(compareEmergencyEnergySumNode])
    set(gca,'XTick',1:4:deltaPLMaxIndex)
%     set(gca,'YTick',0:100000:max(max(compareEmergencyEnergySumNode))) 
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal')

%% 平均丢包率
    figure(2)
    subplot(121)
    plot(100*compareNormalPLRMeanNode(:,1,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(100*compareNormalPLRMeanNode(:,2,noiseShowIndex),'-co','LineWidth',1.5)
    hold on
    plot(100*compareNormalPLRMeanNode(:,3,noiseShowIndex),'-bo','LineWidth',1.5)
    title('Average Packet Loss Rate of Normal Packet Transmission')
    xlabel('Quantity of increasing Path Loss(dB)')
    ylabel('Average Packet Loss Rate(%)')
    %set(gca,'YTick',0:2:40) 
    set(gca,'XTick',1:4:deltaPLMaxIndex)
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal','Location','NorthWest')
    subplot(122)
    plot(100*compareEmergencyPLRMeanNode(:,1,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(100*compareEmergencyPLRMeanNode(:,2,noiseShowIndex),'-co','LineWidth',1.5)
    hold on
    plot(100*compareEmergencyPLRMeanNode(:,3,noiseShowIndex),'-bo','LineWidth',1.5)
    title('Average Packet Loss Rate of Emergency Packet Transmission')    
    ylabel('Average Packet Loss Rate(%)')
    xlabel('Quantity of increasing Path Loss(dB)')
   % axis([1 15 0 max(max(100*compareEmergencyPLRMeanNode))])
    %set(gca,'YTick',0:1:ceil(max(max(100*compareEmergencyPLRMeanNode)))) 
    set(gca,'XTick',1:4:deltaPLMaxIndex)
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal','Location','NorthWest')
        
    
%%平均时延
    figure(3)
    subplot(121)
    plot(compareNormalDelayMeanNode(:,1,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareNormalDelayMeanNode(:,2,noiseShowIndex),'-co','LineWidth',1.5)
    hold on
    plot(compareNormalDelayMeanNode(:,3,noiseShowIndex),'-bo','LineWidth',1.5)
    title('Average Delay of Normal Packet Transmission ')
    xlabel('Quantity of increasing Path Loss(dB)')
    ylabel('Average Delay(ms)')
%     axis([1 11 0 150])
    %set(gca,'YTick',0:10:250) 
    set(gca,'XTick',1:4:deltaPLMaxIndex)
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal')
    
    subplot(122)
    plot(compareEmergencyDelayMeanNode(:,1,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareEmergencyDelayMeanNode(:,2,noiseShowIndex),'-co','LineWidth',1.5)
    hold on
    plot(compareEmergencyDelayMeanNode(:,3,noiseShowIndex),'-bo','LineWidth',1.5)
    title('Average Delay of Emergency Packet Transmission')
    xlabel('Quantity of increasing Path Loss(dB)')
    ylabel('Average Delay(ms)')
%     axis([1 11 0 150])
    %set(gca,'YTick',0:10:250) 
    set(gca,'XTick',1:4:deltaPLMaxIndex)
    set(gca,'XTickLabel',{(1:4:deltaPLMaxIndex)*stepDeltaPL-stepDeltaPL}) 
    legend('Decide','TPC','Optimal')

    %% 观察Energy与PLR的关系    
    figure(4)
    subplot(211)
    plot(compareNormalEnergySumNode(:,3,noiseShowIndex),100*compareNormalPLRMeanNode(:,3,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareNormalEnergySumNode(:,2,noiseShowIndex),100*compareNormalPLRMeanNode(:,2,noiseShowIndex),'-bo','LineWidth',1.5)
    hold on
    plot(compareNormalEnergySumNode(:,1,noiseShowIndex),100*compareNormalPLRMeanNode(:,1,noiseShowIndex),'-go','LineWidth',1.5)
    xlabel('Total Energy Consume of Normal Packet Transmission (uJ)')
    ylabel('Average Packet Loss Rate(%)')
    title('Total Energy Consume VS Average Packet Loss Rate')
    
    subplot(212)
    plot(compareEmergencyEnergySumNode(:,3,noiseShowIndex),100*compareEmergencyPLRMeanNode(:,3,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareEmergencyEnergySumNode(:,2,noiseShowIndex),100*compareEmergencyPLRMeanNode(:,2,noiseShowIndex),'-bo','LineWidth',1.5)
    hold on
    plot(compareEmergencyEnergySumNode(:,1,noiseShowIndex),100*compareEmergencyPLRMeanNode(:,1,noiseShowIndex),'-go','LineWidth',1.5)
    xlabel('Total Energy Consume of Emergency Packet Transmission (uJ)')
    ylabel('Average Packet Loss Rate(%)')
    title('Total Energy Consume VS Average Packet Loss Rate')
    %% 观察Energy与Delay的关系 
    figure(5)
    subplot(211)
    plot(compareNormalEnergySumNode(:,3,noiseShowIndex),compareNormalDelayMeanNode(:,3,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareNormalEnergySumNode(:,2,noiseShowIndex),compareNormalDelayMeanNode(:,2,noiseShowIndex),'-bo','LineWidth',1.5)
    hold on
    plot(compareNormalEnergySumNode(:,1,noiseShowIndex),compareNormalDelayMeanNode(:,1,noiseShowIndex),'-go','LineWidth',1.5)
    xlabel('Total Energy Consume of Normal Packet Transmission (uJ)')
    ylabel('Average Delay(ms)')
    title('Total Energy Consume VS Average Delay')
    
    subplot(212)
    plot(compareEmergencyEnergySumNode(:,3,noiseShowIndex),compareEmergencyDelayMeanNode(:,3,noiseShowIndex),'-ro','LineWidth',1.5)
    hold on
    plot(compareEmergencyEnergySumNode(:,2,noiseShowIndex),compareEmergencyDelayMeanNode(:,2,noiseShowIndex),'-bo','LineWidth',1.5)
    hold on
    plot(compareEmergencyEnergySumNode(:,1,noiseShowIndex),compareEmergencyDelayMeanNode(:,1,noiseShowIndex),'-go','LineWidth',1.5)
    xlabel('Total Energy Consume of Emergency Packet Transmission (uJ)')
    ylabel('Average Delay(ms)')
    title('Total Energy Consume VS Average Delay')
end;

