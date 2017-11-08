%% test 
channelPar
[posPower,posRate,posTime,posMinSumEnergy,posCalTime,KeseeB]=resourceAllocation();

%观察不同姿势状态下的分配资源情况
for m=1:size(posPower,2)
    for i=1:N_Node
        nodeInfo(2*(m-1)+1:2*m,1,i)=posPower{m}(2*(i-1)+1:2*i);
        nodeInfo(2*(m-1)+1:2*m,2,i)=posRate{m}(2*(i-1)+1:2*i);
        nodeInfo(2*(m-1)+1:2*m,3,i)=posTime{m}(2*(i-1)+1:2*i); 
    end; 
end;

save('optimalResult.mat','pos*') %保存优化结果
figure
for i=3:3%N_Node
    hold on
    plot(nodeInfo(1:2:end,1,i))
    hold on
    plot(nodeInfo(2:2:end,1,i))
end;

