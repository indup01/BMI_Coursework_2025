clc; close all; clear all;

%%
load('monkeydata_training.mat')
trialElement = trial(2,2);  % Extract one element (1st trial, 1st angle)
disp(trialElement);         % Display structure fields

%%
figure;
[neurons, spikeCount] = size(trial(2,2).spikes);
% Extract spike data for the specific trial and angle, and slice time steps from 300 to 572
timeSteps = 301:length(spikeCount)-100;
spikeData = trial(2, 2).spikes(:, timeSteps); 

% Plot spike activity for the selected time range
imagesc(spikeData);              % Plot spike activity for time steps 300 to 572
colormap(gray);                  % Use grayscale colormap
xlabel('Time (ms)');
ylabel('Neural Channels');
title(['Raster Plot of Spikes - Trial ', num2str(trial(2,2).trialId)]);
colorbar; % Show intensity scale
%%
figure;
meanFiringRate = mean(trial(2,2).spikes, 1);  % Mean across 98 channels
plot(meanFiringRate, 'LineWidth', 2);
xlabel('Time (ms)');
ylabel('Mean Firing Rate');
title(['Mean Firing Rate Over Time - Trial ', num2str(trial(2,2).trialId)]);
grid on;

%%
figure;
plot(trial(2,2).handPos(1,:), trial(2,2).handPos(2,:), 'LineWidth', 2);
xlabel('X Position');
ylabel('Y Position');
title(['Hand Trajectory - Trial ', num2str(trial(2,2).trialId)]);
grid on;

%%
figure;
plot3(trial(2,2).handPos(1,:), trial(2,2).handPos(2,:), trial(2,2).handPos(3,:), 'LineWidth', 2);
xlabel('X Position');
ylabel('Y Position');
zlabel('Z Position');
title(['3D Hand Trajectory - Trial ', num2str(trial(2,2).trialId)]);
grid on;

%%
% Select a specific trial and angle
trialIdx = 1; % Change this to choose a different trial (1 to 100)
angleIdx = 1; % Change this to choose a different angle (1 to 8)

% Select a neuron randomly
neuronIdx = randi(size(trial(trialIdx, angleIdx).spikes, 1)); 

% Extract the spike activity for the chosen neuron
spikeTrain = trial(trialIdx, angleIdx).spikes(neuronIdx, :); 

% Plot the spike activity over 672 time points
plot(spikeTrain, 'LineWidth', 2);
xlabel('Time (ms)');
ylabel('Spike Activity');
title(['Spike Activity of Neuron ', num2str(neuronIdx), ...
       ' - Trial ', num2str(trial(trialIdx, angleIdx).trialId), ...
       ' - Angle ', num2str(angleIdx)]);
grid on;

%%
% Select a specific trial and angle
trialIdx = 1; % Change this to choose a different trial (1 to 100)
angleIdx = 1; % Change this to choose a different angle (1 to 8)

% Extract spike data for all 98 neurons in the chosen trial and angle
spikeData = trial(trialIdx, angleIdx).spikes;

% Count the number of spikes (1s) at each time point across all neurons
spikeCount = sum(spikeData == 1, 1); % Sum across neurons (rows) for each time step

% Plot the histogram of spike counts per time step
figure;
bar(spikeCount, 'FaceColor', 'b');
xlabel('Time Step');
ylabel('Number of Neurons Spiking');
title(['Spike Count at Each Time Step - Trial ', num2str(trial(trialIdx, angleIdx).trialId), ...
       ' - Angle ', num2str(angleIdx)]);
grid on;

%%
% Select a specific trial and angle
trialIdx = 1; % Change this to choose a different trial (1 to 100)
angleIdx = 1; % Change this to choose a different angle (1 to 8)

% Extract spike data for all 98 neurons in the chosen trial and angle
spikeData = trial(trialIdx, angleIdx).spikes;

% Count the number of spikes (1s) at each time point across all neurons
spikeCount = sum(spikeData == 1, 1); % Sum across neurons (rows) for each time step

% Remove the first 300 and last 100 time steps from the graph (not data)
timeSteps = 301:length(spikeCount)-100; % Time steps to display

% Plot the histogram of spike counts per time step
figure;
bar(timeSteps, spikeCount(timeSteps), 'FaceColor', 'b');
xlabel('Time Step');
ylabel('Number of Neurons Spiking');
title(['Spike Count at Each Time Step - Trial ', num2str(trial(trialIdx, angleIdx).trialId), ...
       ' - Angle ', num2str(angleIdx)]);
grid on;

%% neuron raster across trials
% Select a neuron index (e.g., neuron 10)
neuronIdx = 11;

% Select an angle to analyze (e.g., angle 1)
angleIdx = 1;

% Number of trials
numTrials = size(trial, 1); 

figure; hold on;
colors = lines(numTrials); % Generate distinct colors for trials

for trialIdx = 1:numTrials
    % Extract spike times for this neuron in the current trial
    spikeTrain = trial(trialIdx, angleIdx).spikes(neuronIdx, :); 

    % Find spike time indices (where spikes occur)
    spikeTimes = find(spikeTrain == 1); 

    % Plot spike times for this trial using a different color
    plot(spikeTimes, trialIdx * ones(size(spikeTimes)), '.', ...
         'Color', colors(trialIdx, :), 'MarkerSize', 10);
end

xlabel('Time (ms)');
ylabel('Trial Number');
title(['Raster Plot - Neuron ', num2str(neuronIdx), ' - Angle ', num2str(angleIdx)]);
grid on;
hold off;

%% PSTH
% Define parameters
neuronIdx = 10;   % Select neuron
angleIdx = 1;     % Select movement direction
binSize = 50;     % Bin size in milliseconds
numTrials = size(trial, 1); % Number of trials

% Get the duration of the shortest spike train (ensure safety across trials)
timeSteps = min(arrayfun(@(t) size(t.spikes, 2), trial(:, angleIdx))); 

% Compute number of bins safely
numBins = floor(timeSteps / binSize);

% Initialize PSTH
psth = zeros(1, numBins);

% Loop over trials to collect spike counts
for trialIdx = 1:numTrials
    spikeTrain = trial(trialIdx, angleIdx).spikes(neuronIdx, :); % Extract neuron spikes
    
    for b = 1:numBins
        startIdx = (b-1) * binSize + 1;
        endIdx = min(b * binSize, timeSteps); % Ensure endIdx does not exceed data size
        
        % Ensure indexing does not exceed available data
        if startIdx > timeSteps || endIdx > length(spikeTrain)
            continue; % Skip this iteration safely
        end
        
        % Count spikes within the bin
        psth(b) = psth(b) + sum(spikeTrain(startIdx:endIdx));
    end
end

% Convert to firing rate (spikes/sec)
psth = psth / (numTrials * (binSize / 1000)); % Normalize by trials and bin duration

% Apply Gaussian smoothing
windowSize = 5; % Smoothing window size
smoothedPSTH = smoothdata(psth, 'gaussian', windowSize);

% Plot PSTH
figure;
bar((1:numBins) * binSize, psth, 'FaceColor', [0.6 0.6 0.6]); % Raw histogram
hold on;
plot((1:numBins) * binSize, smoothedPSTH, 'r', 'LineWidth', 2); % Smoothed PSTH
hold off;

xlabel('Time (ms)');
ylabel('Firing Rate (Hz)');
title(['PSTH - Neuron ', num2str(neuronIdx), ' - Angle ', num2str(angleIdx)]);
legend('Raw PSTH', 'Smoothed PSTH');
grid on;


%% hand positions over trials
% Select movement direction (angle)
angleIdx = 3;  % Choose the angle to analyze

% Number of trials
numTrials = size(trial, 1);

figure; hold on;
colors = lines(numTrials); % Generate different colors for each trial

for trialIdx = 1:numTrials
    % Extract hand position for this trial
    handX = trial(trialIdx, angleIdx).handPos(1, :); % X-position
    handY = trial(trialIdx, angleIdx).handPos(2, :); % Y-position

    % Plot trajectory with a unique color
    plot(handX, handY, 'Color', colors(trialIdx, :), 'LineWidth', 1.5);
end

xlabel('X Position');
ylabel('Y Position');
title(['Hand Trajectories Across Trials - Angle ', num2str(angleIdx)]);
legend(arrayfun(@(x) sprintf('Trial %d', x), 1:numTrials, 'UniformOutput', false), 'Location', 'Best');
grid on;
hold off;

%% tuning curves
% Define parameters
neuronIndices = [5, 10, 20]; % Choose some neurons to analyze
numNeurons = length(neuronIndices);
numAngles = size(trial, 2); % 8 movement directions
numTrials = size(trial, 1); % Number of trials
timeSteps = size(trial(1,1).spikes, 2); % Time duration

% Initialize matrices to store firing rates
meanFiringRates = zeros(numNeurons, numAngles);
stdFiringRates = zeros(numNeurons, numAngles);

% Loop over selected neurons
for n = 1:numNeurons
    neuronIdx = neuronIndices(n);
    
    % Loop over movement directions (angles)
    for angleIdx = 1:numAngles
        firingRates = zeros(1, numTrials); % Store firing rates across trials
        
        for trialIdx = 1:numTrials
            spikeTrain = trial(trialIdx, angleIdx).spikes(neuronIdx, :);
            firingRates(trialIdx) = sum(spikeTrain) / (timeSteps / 1000); % Convert to spikes/sec
        end
        
        % Compute mean and standard deviation across trials
        meanFiringRates(n, angleIdx) = mean(firingRates);
        stdFiringRates(n, angleIdx) = std(firingRates);
    end
end

% Define colors for plotting
colors = lines(numNeurons);

% Plot tuning curves
figure; hold on;
for n = 1:numNeurons
    errorbar(1:numAngles, meanFiringRates(n, :), stdFiringRates(n, :), ...
        '-o', 'Color', colors(n, :), 'LineWidth', 2, 'MarkerSize', 8);
end
hold off;

% Formatting the plot
xlabel('Movement Direction (Angle Index)');
ylabel('Mean Firing Rate (Hz)');
title('Tuning Curves for Selected Neurons');
legend(arrayfun(@(x) sprintf('Neuron %d', x), neuronIndices, 'UniformOutput', false), 'Location', 'Best');
grid on;

%% Heatmap of Average Firing Rates Across Neurons & Directions
numNeurons = size(trial(1,1).spikes, 1); % Number of neurons
numAngles = size(trial, 2); % 8 movement directions
avgFiringRates = zeros(numNeurons, numAngles);

% Compute mean firing rate per neuron & direction
for angleIdx = 1:numAngles
    for neuronIdx = 1:numNeurons
        firingRates = [];
        for trialIdx = 1:size(trial,1)
            firingRates(end+1) = sum(trial(trialIdx, angleIdx).spikes(neuronIdx, :)) / (timeSteps / 1000);
        end
        avgFiringRates(neuronIdx, angleIdx) = mean(firingRates);
    end
end

% Plot heatmap
figure;
imagesc(avgFiringRates);
colormap(hot);
colorbar;
xlabel('Movement Direction (Angle Index)');
ylabel('Neurons');
title('Neuron Tuning Across Movement Directions');

%% SVD for Principal Component Analysis (PCA) on Neural Activity
% Flatten data: Each row is a trial, each column is a neuron’s average activity
neuralData = zeros(numTrials * numAngles, numNeurons);

count = 1;
for angleIdx = 1:numAngles
    for trialIdx = 1:numTrials
        neuralData(count, :) = mean(trial(trialIdx, angleIdx).spikes, 2); % Mean activity per neuron
        count = count + 1;
    end
end

% Perform Singular Value Decomposition (SVD)
[U, S, V] = svd(neuralData, 'econ');  % SVD decomposition

% Plot the first two principal components (equivalent to PCA)
figure;
scatter(U(:, 1), U(:, 2), 50, 'filled');
xlabel('PC1');
ylabel('PC2');
title('SVD of Neural Firing Rates');
grid on;

%% Correlation Matrix of Neuron Activity
neuronIdx = 1:20; % Pick first 20 neurons
trialIdx = 1; 
angleIdx = 1; 

% Extract spike activity for selected neurons
neuronData = trial(trialIdx, angleIdx).spikes(neuronIdx, :);

% Compute correlation matrix
corrMatrix = corrcoef(neuronData');

% Plot heatmap of correlations
figure;
imagesc(corrMatrix);
colormap(jet);
colorbar;
title('Neuron Firing Correlation');
xlabel('Neuron');
ylabel('Neuron');

%% Movement Decoding: Predict Direction from Neural Activity

% Flatten data: Each row is a trial, each column is a neuron’s average activity
features = [];  % Neural activity features
labels = [];    % Movement directions

% Collect data for classification
for angleIdx = 1:numAngles
    for trialIdx = 1:numTrials
        features = [features; mean(trial(trialIdx, angleIdx).spikes, 2)']; % Mean firing rate per neuron
        labels = [labels; angleIdx]; % Movement direction label
    end
end

% Normalize the features manually (z-score normalization)
meanFeatures = mean(features, 1);  % Compute the mean of each feature (column)
stdFeatures = std(features, 0, 1); % Compute the standard deviation of each feature (column)

% Apply z-score normalization manually
features = (features - meanFeatures) ./ stdFeatures;

% Manually split the dataset into training and testing sets
numData = length(labels);          % Total number of data points
numTrain = round(0.8 * numData);   % 80% for training
numTest = numData - numTrain;      % 20% for testing

% Randomly shuffle the data indices
indices = randperm(numData);

% Select training and test sets
trainIdx = indices(1:numTrain);
testIdx = indices(numTrain+1:end);

% Separate features and labels for training and testing
trainFeatures = features(trainIdx, :);
trainLabels = labels(trainIdx);
testFeatures = features(testIdx, :);
testLabels = labels(testIdx);

% Manually implement k-NN classifier
k = 5;  % Number of neighbors
numTest = size(testFeatures, 1);  % Number of test samples
predictedLabels = zeros(numTest, 1);  % Initialize predicted labels

for i = 1:numTest
    % Compute Euclidean distances between the current test sample and all training samples
    distances = sqrt(sum((trainFeatures - testFeatures(i, :)).^2, 2));
    
    % Get the indices of the k smallest distances
    [~, sortedIdx] = sort(distances);
    nearestNeighbors = trainLabels(sortedIdx(1:k));
    
    % Assign the most common label among the k nearest neighbors
    predictedLabels(i) = mode(nearestNeighbors);
end

% Compute accuracy
accuracy = sum(predictedLabels == testLabels) / length(predictedLabels) * 100;
disp(['Manual k-NN Classification Accuracy: ', num2str(accuracy), '%']);

%%
% Try different values of k (e.g., from 1 to 15)
k_values = 1:15; 
accuracies = zeros(length(k_values), 1);

for k = k_values
    % Manually implement k-NN classifier for each k
    predictedLabels = zeros(numTest, 1);  % Initialize predicted labels
    for i = 1:numTest
        % Compute Euclidean distances between the current test sample and all training samples
        distances = sqrt(sum((trainFeatures - testFeatures(i, :)).^2, 2));
        
        % Get the indices of the k smallest distances
        [~, sortedIdx] = sort(distances);
        nearestNeighbors = trainLabels(sortedIdx(1:k));
        
        % Assign the most common label among the k nearest neighbors
        predictedLabels(i) = mode(nearestNeighbors);
    end

    % Compute accuracy for this value of k
    accuracies(k) = sum(predictedLabels == testLabels) / length(predictedLabels) * 100;
end

% Plot accuracy vs k
figure;
plot(k_values, accuracies, '-o');
xlabel('Number of Neighbors (k)');
ylabel('Classification Accuracy (%)');
title('k-NN Classification Accuracy for Different k');
grid on;

