% Test Script to give to the students, March 2015
% clc; clear; close all;
%% Continuous Position Estimator Test Script
% This function first calls the function "positionEstimatorTraining" to get
% the relevant modelParameters, and then calls the function
% "positionEstimator" to decode the trajectory. 

%%
function RMSE = testFunction_for_students_updated(teamName, figname, use_rng)

% Check if use_rng argument is provided, otherwise default to true
if nargin < 2, figname = ''; end
if nargin < 3, use_rng = true; end

% Set random number generator
if use_rng
    rng(2013);
    disp('rng set to 2013');
else
    disp('No rng set');
end

% Star time
tic

% load monkeydata_training.mat
load monkeydata0.mat

ix = randperm(length(trial));

addpath(teamName);

% Select training and testing data (you can choose to split your data in a different way if you wish)
trainingData = trial(ix(1:50),:);
testData = trial(ix(51:end),:);

fprintf('Testing the continuous position estimator...')

meanSqError = 0;
n_predictions = 0;  

%Classification Accuracy
correctCount   = 0;  % how many times we guessed the right direction
totalCount     = 0;  % how many direction predictions we made
predictedLabel = zeros(size(testData,1), 8); 

% Initialize storage for per-bin statistics
timeBins = 320:20:560;  % same as 'times'
nBins = length(timeBins);
correctPerBin = zeros(1, nBins);
totalPerBin = zeros(1, nBins);
squaredErrorPerBin = zeros(1, nBins);
countPerBin = zeros(1, nBins);

figure
hold on
axis square
grid

% Train Model
modelParameters = positionEstimatorTraining(trainingData);

for tr=1:size(testData,1)
    display(['Decoding block ',num2str(tr),' out of ',num2str(size(testData,1))]);
    pause(0.001)
    for direc=randperm(8) 
        decodedHandPos = [];

        times=320:20:size(testData(tr,direc).spikes,2);

        for t=times
            past_current_trial.trialId = testData(tr,direc).trialId;
            past_current_trial.spikes = testData(tr,direc).spikes(:,1:t); 
            past_current_trial.decodedHandPos = decodedHandPos;

            past_current_trial.startHandPos = testData(tr,direc).handPos(1:2,1); 

            if nargout('positionEstimator') == 3
                [decodedPosX, decodedPosY, newParameters] = positionEstimator(past_current_trial, modelParameters);
                modelParameters = newParameters;
            elseif nargout('positionEstimator') == 2
                [decodedPosX, decodedPosY] = positionEstimator(past_current_trial, modelParameters);
            end

            decodedPos = [decodedPosX; decodedPosY];
            decodedHandPos = [decodedHandPos decodedPos];

            meanSqError = meanSqError + norm(testData(tr,direc).handPos(1:2,t) - decodedPos)^2;          
            
            % RMSE per bin
            binIdx = find(timeBins == t);
            squaredError = norm(testData(tr,direc).handPos(1:2,t) - decodedPos)^2;
            squaredErrorPerBin(binIdx) = squaredErrorPerBin(binIdx) + squaredError;
            countPerBin(binIdx) = countPerBin(binIdx) + 1;
            
            % Classification per bin
            if modelParameters.actualLabel == direc
                correctPerBin(binIdx) = correctPerBin(binIdx) + 1;
            end
            totalPerBin(binIdx) = totalPerBin(binIdx) + 1;

        end

        n_predictions = n_predictions+length(times);
        hold on
        plot(decodedHandPos(1,:),decodedHandPos(2,:), 'r');
        plot(testData(tr,direc).handPos(1,times),testData(tr,direc).handPos(2,times),'b')

        % Classification code
        predictedDir = modelParameters.actualLabel;  % The label your code just assigned
        predictedLabel(tr, direc) = predictedDir;
        % Compare predictedDir to the true direction (= direc)
        if predictedDir == direc
            correctCount = correctCount + 1;
        end
        totalCount = totalCount + 1;
        % -----END----- %
    end
end

legend('Decoded Position', 'Actual Position')

RMSE = sqrt(meanSqError/n_predictions); 

classificationAccuracy = correctCount / totalCount;

% End timing and store the result
elapsedTime = toc;  

rmpath(genpath(teamName))

% Display the elapsed time
fprintf('\nExecution time: %.2f seconds\n', elapsedTime);
fprintf('RMSE: %.4f\n', RMSE);
fprintf('Weighted Rank: %.2f\n', 0.9*RMSE + 0.1*elapsedTime);
fprintf('Classification Accuracy (final) = %.2f%% \n', classificationAccuracy * 100);

% Final stats per time bin
meanRMSE_perBin = sqrt(squaredErrorPerBin ./ countPerBin);
accuracy_perBin = correctPerBin ./ totalPerBin;
% Display as table
fprintf('\nTime Bin (ms) | Accuracy (%%) | RMSE\n');
fprintf('--------------|---------------|--------\n');
for i = 1:nBins
    fprintf('%10d     |     %6.2f     | %.2f\n', timeBins(i), accuracy_perBin(i)*100, meanRMSE_perBin(i));
end

disp(['Overall RMSE (mean over time bins) ' num2str(mean(meanRMSE_perBin))]);
disp(['Overall classification accuracy: ' num2str(mean(accuracy_perBin)*100)])

if ~isempty(figname), save_figure(gcf, 'figures', figname, 'pdf', 'vector', false); end
end