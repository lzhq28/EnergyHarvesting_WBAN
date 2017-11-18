function [ miu_th ] = calEquPLRThreshold( Nodes, Channel, Constraints, precision, re_cal_miu_state,t_cor_EH )
%calEquPLRThreshold 计算等效丢包率门限，即满足丢包率的平均信噪比
%输入
%   Nodes par.Nodes各个节点的基本信息
%   Channel 信道相关参数
%   Constraints 服务质量约束
%   precision 搜索精度
%   re_cal_miu_state  是否重新计算miu值，值为0表示不重新计算，而是从文件中读取，否则重新计算。
    [ path_names ] = configurePaths(t_cor_EH);
    miu_path_name = path_names.miu_th;
    if exist(miu_path_name,'file') && ~re_cal_miu_state
        disp('************Load miu threshold from file************')
        load(miu_path_name); % 从文件中加载miu_th
        return;
    end
    disp('************Recaculate miu threshold************')
    num_pos = size(Nodes.Sigma,1);
    num_nodes = size(Nodes.Sigma,2);
    PLR_th = Constraints.Nor_PLR_th;
    for ind_pos = 1:num_pos
        for ind_node = 1:num_nodes
            disp(strcat(['>>>>>>>>>>>>>>>>>(ind_pos,ind_node)：',num2str(ind_pos),',',num2str(ind_node),'<<<<<<<<<<<<<<<<<<']))
            packet_length = Nodes.packet_length(ind_node);
            sigma = Nodes.Sigma(ind_pos,ind_node);
            miu_th(ind_pos,ind_node) = findMiuThreshold(sigma, packet_length, PLR_th, Channel, precision);
        end
    end
    save(miu_path_name,'miu_th');
end

