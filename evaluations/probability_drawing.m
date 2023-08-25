clear;
clc;

fileID1 = fopen('output5_1server_15log.txt', 'r'); 
data1 = textscan(fileID1, '%d');   
fclose(fileID1); 
integers1 = data1{1};
prob1 = histcounts(integers1, 'Normalization', 'probability');
cumulativeProb1 = cumsum(prob1)*100;

fileID2 = fopen('output5_2server_15log.txt', 'r');
data2 = textscan(fileID2, '%d'); 
fclose(fileID2);
integers2 = data2{1};    
prob2 = histcounts(integers2, 'Normalization', 'probability');
cumulativeProb2 = cumsum(prob2)*100;

fileID3 = fopen('output5_3server_15log.txt', 'r');
data3 = textscan(fileID3, '%d'); 
fclose(fileID3);
integers3 = data3{1};    
prob3 = histcounts(integers3, 'Normalization', 'probability');
cumulativeProb3 = cumsum(prob3)*100;

fileID4 = fopen('output5_4server_15log.txt', 'r');
data4 = textscan(fileID4, '%d'); 
fclose(fileID4);
integers4 = data4{1};    
prob4 = histcounts(integers4, 'Normalization', 'probability');
cumulativeProb4 = cumsum(prob4)*100;

figure;
hold on;

plot([0; cumulativeProb1(:)], 'b-', 'LineWidth', 1);
plot([0; cumulativeProb2(:)], 'r-', 'LineWidth', 1);
plot([0; cumulativeProb3(:)], 'g-', 'LineWidth', 1);
plot([0; cumulativeProb4(:)], 'k-', 'LineWidth', 1);

hold off;

title('Cumulative Probability Distribution Comparison (15 log, 5 members)');
xlabel('Time(ms)');
ylabel('Cumulative Probability %');
legend('1 new member','2 new members', '3 new members','4  new members');
axis([-1, 20, -10, 110]);
