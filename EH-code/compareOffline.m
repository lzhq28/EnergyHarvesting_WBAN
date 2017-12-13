%% offline方法：Optimal power allocation for outage probability minimization in fading channels with energy harvesting constraints
% 细节：
%   1. 根据能量到达情况采用定向注水法进行功率配置
%   2. 根据链路情况来确定最优的传输功率（主要是这个）
function compareOffline(shadow_seq, pos_seq, EH_collect_seq)
    N_frame = size( pos_seq,2);
    N_slot = size(shadow_seq,2)/N_frame;
    


end
