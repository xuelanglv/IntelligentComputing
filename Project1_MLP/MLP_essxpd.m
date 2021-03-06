clear all
close all

% Load the data in
data_file = 'threeclouds.data';
% data_file = 'wine.data';

if ~strcmp(data_file, 'mnist')
    load(data_file);
end

if strcmp(data_file, 'threeclouds.data')
    data = threeclouds;
elseif strcmp(data_file, 'wine.data')
    data = wine;
elseif strcmp(data_file, 'semeion.data')
    data = semeion; 
    
    tmp = semeion(:,257:end);
    for i = 1:size(tmp,1)
        [~, labels(i)] = max(tmp(i, :));
    end
    
    data = [labels' data(:,1:256)];
elseif strcmp(data_file, 'mnist')
    imageName = 'mnist/t10k-images-idx3-ubyte';
    data = loadMNISTImages(imageName);
    labelName = 'mnist/t10k-labels-idx1-ubyte';
    labels = loadMNISTLabels(labelName) + 1;
    data = [labels data'];
end

% Shuffle the data
data = data(randperm(size(data,1)),:);

% Seperate into network input data and labels
labels = data(:,1);
input = data(:, 2:size(data,2));

% Clean the input (Normalize)
for col = 1:size(input,2)
     input(:,col) = (input(:,col) - mean(input(:,col),1)) ./ (.000001+std(input(:,col),0,1));
end

% Determine dimensionality, number of classes, and number of examples
numDimensions = size(2:size(data,2), 2);
numClasses = size(unique(data(:,1)), 1);
numExamples = size(data(:,1), 1);

% Create the one hot expected output
expectedOutput = zeros(size(2:size(data,2),1), numClasses);
for i = 1:size(labels, 1)
    expectedOutput(i, labels(i)) = 1;
end

% Divide into Training, Validation, and Test sets
ssizes = [.8, .1, .1];  % Set sizes
c = cumsum(ssizes);     % Cummulative sum
trainingData = input(1:floor(numExamples*c(1)), :);
trainingLabels = labels(1:floor(numExamples*c(1)), :);
trainingExpectedOutput = expectedOutput(1:floor(numExamples*c(1)), :);

validationData = input(floor(numExamples*c(1))+1:floor(numExamples*c(2)), :);
validationLabels = labels(floor(numExamples*c(1))+1:floor(numExamples*c(2)), :);
validationExpectedOutput = expectedOutput(floor(numExamples*c(1))+1:floor(numExamples*c(2)), :);

testData = input(floor(numExamples*c(2))+1:numExamples, :);
testLabels = labels(floor(numExamples*c(2))+1:numExamples, :);
testExpectedOutput = expectedOutput(floor(numExamples*c(2))+1:numExamples, :);

% If 2d or 3d then plot the points with a scatter
if numDimensions == 2
    figure;
    scatter(input(:,1)', input(:,2)', 15, expectedOutput, 'filled');
elseif numDimensions == 3
    scatter3d(input(:,1)', input(:,2)', input(:,3), 15, labels', 'filled');
end

% Network Config
eta = .1;
maxEpoch = 100;
actFunc = @sigmoid;
actFuncGrad = @sigmoid_grad;
layerSizes = [((ceil(sqrt(numDimensions))/2)+1).^2, numClasses]; % Output layer is one hot 

numHiddenLayers = size(layerSizes, 2) - 1;
outputLayer = size(layerSizes, 2);

% Initialize the network
% rng(0);
[W, b] = initNetwork(layerSizes, numDimensions);


% activations = forwardPass(actFunc, input(1,:), W, b);
% W{1}(1, 1) = .1;
% W{1}(2, 1) = .1;
% W{1}(1, 2) = .25;
% W{1}(2, 2) = .7;
% W{2}(1, 1) = .4;
% W{2}(2, 1) = .6;
% W{2}(1, 2) = .5;
% W{2}(2, 2) = .3;

% test = forwardPass(actFunc, input(2,:), W, b);

% Train the network
s = sprintf('\nEpoch\t|\tValidation accuracy\n---------------------------------');
disp(s);

for e = 1:maxEpoch
    for k = 1:size(trainingData,1)
        [delta_W, delta_b] = backPropagation(actFunc, actFuncGrad, W, b, trainingData(k,:), trainingExpectedOutput(k,:));

        for i = 1:size(W,2)
            W{i} = W{i} + eta .* delta_W{i};
            b{i} = b{i} + eta .* delta_b{i};
        end
    end
    
    p = predict(actFunc, validationData, W, b);
    numCorrect = numel(find(p == validationLabels));
    s = sprintf('%i\t\t|\t%.2f%%', e, (numCorrect/size(validationLabels,1))*100);
    disp(s);
end

% test = forwardPass(actFunc, input(2,:), W, b);

p = predict(actFunc, testData, W, b);
numCorrect = numel(find(p == testLabels));
s = sprintf('\nTest accuracy: %.2f%%', (numCorrect/size(testLabels,1))*100);
disp(s);

p = predict(actFunc, input, W, b);
numCorrect = numel(find(p == labels));
s = sprintf('Overall accuracy: %.2f%%\n', (numCorrect/size(labels,1))*100);
disp(s);

% If three clouds then we can plot the data and show which points were
% correctly classified and which weren't
if strcmp(data_file, 'threeclouds.data')
    % Run all of the data through the network
    p = predict(actFunc, input, W, b);
    Correct = find(p == labels);
    Incorrect = find(p ~= labels);
    
    a = zeros(size(p,1), numClasses);
    for i = 1:size(a, 1)
        a(i, p(i)) = 1;
    end
    
    scatter(input(Correct,1)', input(Correct,2)', 15, a(Correct,:), 'filled'); hold on;
    for i = 1:size(Incorrect,1)
        scatter(input(Incorrect(i),1)', input(Incorrect(i),2)', 25, 'MarkerEdgeColor', a(Incorrect(i),:), 'MarkerFaceColor', expectedOutput(Incorrect(i),:), 'LineWidth', 1);
    end
    
    % New plot using meshgird 
    [X, Y] = meshgrid(-2.5:.01:2.5, -2.5:.01:2);
    points = [X(:) Y(:)];
    p = predict(actFunc, points, W, b);
    
    a = zeros(size(p,1), numClasses);
    for i = 1:size(p,1)
        a(i, p(i)) = 1;
    end
    figure;
    scatter(points(:,1)', points(:,2)', 15, a(:,:), 'filled');
end

if strcmp(data_file, 'semeion.data')
%     incorrect_loc = find(p ~= labels);
%     incorrect = input(incorrect_loc, :);
%     
%     for i = 1:size(incorrect,1)
%         incorrect_image = reshape(incorrect(i,:), 16, 16);
%         name = sprintf('Class: %i   Prediction: %i', labels(incorrect_loc(i))-1, p(incorrect_loc(i))-1);
%         figure('Name', name);
%         imshow(incorrect_image');
%     end

%     % Visualize learned weights
%     if layerSizes(1) == 64 && size(layerSizes, 2) == 2
%         for i = 1:layerSizes(1)
%             weights = reshape(W{1}(:,i), 16, 16);
%             a = 0;
%             b = 1;
%             weights = weights - mean(weights(:));
%             weights = ((b - a) * (weights - min(weights(:)))) / (max(weights(:)) - min(weights(:)));
%             figure;
%             imshow(weights);
%         end
%     end

    display_network(W{1});
end

if strcmp(data_file, 'mnist')
    display_network(W{1});
end