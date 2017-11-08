function lifetime=calLifetime(dataName,threshold)
    load(dataName) %��������   
    energyNormalPerFrame=[];
    energyEmergencyPerFrame=[];
    energyPerFrame=[];
    for i=1:N_Node
        for m=1:N_ch
            %����ʱ�ӣ���ͳ��ÿһ������ƽ��ʱ�ӣ�Ȼ����ͳ���ܵ�ƽ��ʱ��
            %������
            energyNormalPerFrame(m,i)=0 ; %����ÿ����֡�ڵ��ܺ�
            ind=find(packetNormalInfo{i}(:,2)==m);
            energyNormalPerFrame(m,i)=(a+1)*packetNormalInfo{i}(ind,4)'*packetNormalInfo{i}(ind,5)+repmat(b,1,max(size(ind)))*packetNormalInfo{i}(ind,5);
            %������
            energyEmergencyPerFrame(m,i)=0 ; %����ÿ����֡�ڵ��ܺ�
            ind2=find(packetEmergencyInfo{i}(:,2)==m);
            if ind2
                energyEmergencyPerFrame(m,i)=(a+1)*packetEmergencyInfo{i}(ind2,4)'*packetEmergencyInfo{i}(ind2,5)+repmat(b,1,max(size(ind2)))*packetEmergencyInfo{i}(ind2,5);
            else
                energyEmergencyPerFrame(m,i)=0;
            end
            energyPerFrame(m,i)=sum(energyNormalPerFrame(1:m,i)+energyEmergencyPerFrame(1:m,i));
        end
    end 
    %�ҵ����ܺ�Ϊthreshold�ĳ�֡
    energySum=max(energyPerFrame,[],2);
    ind=find(energySum>threshold);
    if ind
        lifetime=ind(1);        
    else
        lifetime=N_ch;
        lifetime=ceil(threshold*1.0/energySum(lifetime)*N_ch);
    end
