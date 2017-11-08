%% 观察系统分配结果，并分析
clc
clear all
PNoise=-94
deltaPL=16
N_Node=5
T_Slot=0.5
%channelPar(PNoise,deltaPL)
% [posPower,posRate,posTime,posMinSumEnergy,posCalTime]=resourceAllocationEnhance2(PNoise,deltaPL);
load(strcat('channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('optimalValue_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
load(strcat('finalResult0_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat'))
%观察不同姿势状态下的分配资源情况
for m=1:size(posPower,2)
    for i=1:N_Node
        nodeInfo(2*(m-1)+1:2*m,1,i)=posPower{m}(2*(i-1)+1:2*i);
        nodeInfo(2*(m-1)+1:2*m,2,i)=posRate{m}(2*(i-1)+1:2*i);
        nodeInfo(2*(m-1)+1:2*m,3,i)=posTime{m}(2*(i-1)+1:2*i); 
    end; 
end;

%% 显示发射功率的优化结果
%显示正常包的优化功率结果
    color={'-bo','-go','-ro','-ko','-co'}
    figure(1)
    subplot(121)
    for i=1:N_Node
        hold on
        plot(nodeInfo(1:2:end,1,i),color{i},'LineWidth',1.5);    
    end;
    xlabel('Different Postures')
    ylabel('Optimal value of TX power(mW)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
    axis([  1 3 0 max(max(nodeInfo(:,1,:)))])
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Optimal value of TX power for Normal Packet Transmission ')



    % 显示紧急包的优化功率结果
    subplot(122)
    for i=1:N_Node
        hold on
        plot(nodeInfo(2:2:end,1,i),color{i},'LineWidth',1.5);  
    end;
    xlabel('Different Postures')
    ylabel('Optimal value of TX power(mW)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
    axis([  1 3 0 max(max(nodeInfo(:,1,:)))])
    set(gca, 'XTick',[ 1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Optimal value of TX power for Emergency Packet Transmission ')

%% 显示时隙分配结果
% 显示正常包
    color={'-bo','-g*','-rp','-k^','-cs'}
    figure(2)
    subplot(121)
    for i=1:N_Node
        hold on
        plot(ceil(nodeInfo(1:2:end,3,i)./T_Slot),color{i},'LineWidth',1.5);    
    end;
    xlabel('Different Postures')
    ylabel('Number of schedule time slots')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
    axis([1 3 0 max(max(ceil(nodeInfo(1:2:end,3,i)./T_Slot)))+4])
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Number of schedule time slots for Normal Packet Transmission ')


% 显示紧急包
   subplot(122)
    for i=1:N_Node
        hold on
        plot(ceil(nodeInfo(2:2:end,3,i)./T_Slot),color{i},'LineWidth',1.5)
    %     hold on
    %     plot(nodeInfo(2:2:end,1,i),color{i})

    end;
    xlabel('Different Postures')
    ylabel('Number of schedule time slots')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
  axis([1 3 0 max(max(ceil(nodeInfo(2:2:end,3,i)./T_Slot)))+4])
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Number of schedule time slots for Emergency Packet Transmission ')
%% 显示发射速率分配结果
    color={'-bo','-go','-ro','-ko','-co'}
    figure(3)
    subplot(121)
    for i=1:N_Node
        hold on
        plot(nodeInfo(1:2:end,2,i),color{i},'LineWidth',1.5);    
    end;
    xlabel('Different Postures')
    ylabel('Optimal value of TX Rates(Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
    
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Optimal value of TX Rates for Normal Packet Transmission ')


% 显示紧急包
   subplot(122)
    for i=1:N_Node
        hold on
        plot(nodeInfo(2:2:end,2,i),color{i},'LineWidth',1.5)
    %     hold on
    %     plot(nodeInfo(2:2:end,1,i),color{i})

    end;
    xlabel('Different Postures')
    ylabel('Optimal value of TX Rates(Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
    
    set(gca, 'XTick',[1 2 3])
    set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
    title('Optimal value of TX Rates for Emergency Packet Transmission ')
    
%% 观察路径损耗情况
figure(4)
subplot(211)
bar(NoPL,0.3)

xlabel('Different Nodes')
ylabel('Path Loss(dB)')
set(gca, 'XTick',[1 2 3 4 5])
set(gca,'XTickLabel',{'Node1','Node2','Node3','Node4','Node5'}) 
title('Path Loss of different nodes ')
%观察不同姿势状态下不同节点的
subplot(212)
for n=1:N_Node
    hold on
    plot(NodeKese(:,n),color{n},'LineWidth',1.5)
end;
xlabel('Different Nodes')
ylabel('Standard Deviation of Shadowing(dB)')
legend('Node1','Node2','Node3','Node4','Node5','Location','NorthWest')
axis([  1 3 2 9]) 
set(gca, 'XTick',[1 2 3])
set(gca,'XTickLabel',{'Stand','Walk','Run'}) 
title('Standard Deviation of Shadowing of different postures  ')


