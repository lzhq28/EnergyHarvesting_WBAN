function [ miu_th ] = calEquPLRThreshold( Nodes, Channel, Constraints, precision, re_cal_miu_state )
%calEquPLRThreshold �����Ч���������ޣ������㶪���ʵ�ƽ�������
%����
%   Nodes par.Nodes�����ڵ�Ļ�����Ϣ
%   Channel �ŵ���ز���
%   Constraints ��������Լ��
%   precision ��������
%   re_cal_miu_state  �Ƿ����¼���miuֵ��ֵΪ0��ʾ�����¼��㣬���Ǵ��ļ��ж�ȡ���������¼��㡣
    miu_path_name = 'miu_parameter.mat';
    if exist(miu_path_name,'file') && ~re_cal_miu_state
        disp('************Load miu threshold from file************')
        load(miu_path_name); % ���ļ��м���miu_th
        return;
    end
    disp('************Recaculate miu threshold************')
    num_pos = size(Nodes.Sigma,1);
    num_nodes = size(Nodes.Sigma,2);
    PLR_th = Constraints.Nor_PLR_th;
    for ind_pos = 1:num_pos
        for ind_node = 1:num_nodes
            disp(strcat(['>>>>>>>>>>>>>>>>>(ind_pos,ind_node)��',num2str(ind_pos),',',num2str(ind_node),'<<<<<<<<<<<<<<<<<<']))
            packet_length = Nodes.packet_length(ind_node);
            sigma = Nodes.Sigma(ind_pos,ind_node);
            miu_th(ind_pos,ind_node) = findMiuThreshold(sigma, packet_length, PLR_th, Channel, precision);
        end
    end
    save(miu_path_name,'miu_th');
end

