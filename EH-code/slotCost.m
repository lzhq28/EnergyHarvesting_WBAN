function [ output_args ] = slotCost( num_allocate_slots, arrival_bits, buffer_bits, tran_rate )
% slotCost ����������Դ
%   �˴���ʾ��ϸ˵��


end

N_arr = 10;
N_buf = 20;
N_sum = (N_arr+N_buf);
x=0:0.1:2*N_sum
y=(power(N_sum,2)-power((x-N_sum),2))

plot(x,y)