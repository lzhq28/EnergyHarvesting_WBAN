function lifetime=calLifetime(dataName,threshold)
    load(dataName) %加载数据   
    energyNormalPerFrame=[];
    energyEmergencyPerFrame=[];
    energyPerFrame=[];
    for i=1:N_Node
        for m=1:N_ch
            %计算时延，先统计每一个包的平均时延，然后再统计总的平均时延
            %正常包
            energyNormalPerFrame(m,i)=0 ; %保存每个超帧内的能耗
            ind=find(packetNormalInfo{i}(:,2)==m);
            energyNormalPerFrame(m,i)=(a+1)*packetNormalInfo{i}(ind,4)'*packetNormalInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetNormalInfo{i}(ind,5);
            %紧急包
            energyEmergencyPerFrame(m,i)=0 ; %保存每个超帧内的能耗
            ind2=find(packetEmergencyInfo{i}(:,2)==m);
            if ind2
                energyEmergencyPerFrame(m,i)=(a+1)*packetEmergencyInfo{i}(ind2,4)'*packetEmergencyInfo{i}(ind2,5)+repmat(b,1,max(size(ind2)))*packetEmergencyInfo{i}(ind2,5);
            else
                energyEmergencyPerFrame(m,i)=0;
            end
            energyPerFrame(m,i)=sum(energyNormalPerFrame(1:m,i)+energyEmergencyPerFrame(1:m,i));
        end
    end 
    %找到当能耗为threshold的超帧
    energySum=max(energyPerFrame,[],2);
    ind=find(energySum>threshold);
    if ind
        lifetime=ind(1);        
    else
        lifetime=N_ch;
        lifetime=ceil(threshold*1.0/energySum(lifetime)*N_ch);
    end
