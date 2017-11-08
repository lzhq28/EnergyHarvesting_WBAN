function [ tranQueue, arrivalQueue, bufferQueue ] = nodeTranPerFrame(cur_frame_ind, cur_pos, cur_shadow, residue_energy, Allocation, Node, Constraints, tranQueue, arrivalQueue, bufferQueue)
%nodeTranPerFrame 每个节点在所分配的资源的条件下的数据传输情况
%输入：
%   cur_frame_ind 当前超帧的索引号
%   cur_pos 当前的身体姿势状态
%   cur_shadow 当前节点在当前超帧各个时隙内的阴影衰落
%   residue_energy 节点剩余能量
%   tranQueue 数据包传输队列，包含数据包传输的信息
%   arrivalQueue 数据包达到队列
%   bufferQueue 缓存状态队列
%   Allocation 所分配的额资源，包括传输功率，船速速率，   
%   Node 节点的基本信息，包括数据包到达情况、数据包长度、节点的信道情况（sigma）
%   Constraints 数据包服务质量约束等
    
    

end

