function output_file = prepare_real_te_data(raw_input_file, dag_input_file, state_count)
%PREPARE_REAL_TE_DATA Prepare Tennessee-Eastman data for discrete BN learning.
%
% Expected inputs:
%   raw_input_file : optional explicit path to continuous TE observations
%   dag_input_file : optional explicit path to the reference TE DAG
%   state_count    : number of discrete states for quantile discretization
%
% Default file lookup inside raw/:
%   te_raw.mat / te_raw.csv / te_raw.tsv / te_raw.txt
%   te_true_dag.mat / te_true_dag.csv / te_true_dag.tsv / te_true_dag.txt

if nargin < 1, raw_input_file = ''; end
if nargin < 2, dag_input_file = ''; end
if nargin < 3 || isempty(state_count), state_count = 3; end

experiment_dir = fileparts(mfilename('fullpath'));
raw_dir = fullfile(experiment_dir, 'raw');
data_dir = fullfile(experiment_dir, 'Data');
if ~exist(data_dir, 'dir'), mkdir(data_dir); end

[continuous_data, data_node_names, raw_source_file] = load_te_observations(raw_dir, raw_input_file);
[true_dag, dag_node_names, dag_source_file] = load_te_reference_dag(raw_dir, dag_input_file);

if isempty(data_node_names)
    data_node_names = dag_node_names;
end
if isempty(dag_node_names)
    dag_node_names = data_node_names;
end

[continuous_data, node_names, true_dag] = align_te_data_and_dag(continuous_data, data_node_names, true_dag, dag_node_names);

node_count = size(continuous_data, 1);
sample_count = size(continuous_data, 2);
discrete_data = zeros(node_count, sample_count);
bin_edges = cell(node_count, 1);
for i = 1:node_count
    [discrete_data(i, :), bin_edges{i}] = quantile_discretize(continuous_data(i, :), state_count);
end
node_sizes = max(discrete_data, [], 2)';

output_file = fullfile(data_dir, 'te_real_discrete.mat');
save(output_file, 'continuous_data', 'discrete_data', 'node_names', 'node_sizes', ...
    'true_dag', 'bin_edges', 'sample_count', 'state_count', 'raw_source_file', 'dag_source_file');
fprintf('Saved TE discrete data: %s\n', output_file);
end

function [data, node_names, source_file] = load_te_observations(raw_dir, raw_input_file)
source_file = resolve_input_file(raw_dir, raw_input_file, ...
    {'te_raw.mat', 'te_raw.csv', 'te_raw.tsv', 'te_raw.txt', 'datasetTE.csv', 'datasetTE.txt'});
[data, node_names] = load_numeric_dataset(source_file);
end

function [dag, node_names, source_file] = load_te_reference_dag(raw_dir, dag_input_file)
source_file = resolve_input_file(raw_dir, dag_input_file, ...
    {'te_true_dag.mat', 'te_true_dag.csv', 'te_true_dag.tsv', 'te_true_dag.txt', 'TEGroundTruth.txt', 'TEGroundTruth.csv'});
[dag, node_names] = load_dag_dataset(source_file);
end

function input_file = resolve_input_file(raw_dir, explicit_file, candidates)
if ~isempty(explicit_file)
    input_file = explicit_file;
    if ~exist(input_file, 'file')
        error('Specified file not found: %s', input_file);
    end
    return;
end

for i = 1:numel(candidates)
    candidate = fullfile(raw_dir, candidates{i});
    if exist(candidate, 'file')
        input_file = candidate;
        return;
    end
end

error('Required TE input file not found in %s.', raw_dir);
end

function [data, node_names] = load_numeric_dataset(source_file)
[~, ~, ext] = fileparts(source_file);
switch lower(ext)
    case '.mat'
        loaded = load(source_file);
        [data, node_names] = parse_mat_data(loaded);
    otherwise
        [data, node_names] = parse_text_data(source_file);
end

data = double(data);
if size(data, 1) > size(data, 2)
    data = data';
end
end

function [dag, node_names] = load_dag_dataset(source_file)
[~, ~, ext] = fileparts(source_file);
switch lower(ext)
    case '.mat'
        loaded = load(source_file);
        [dag, node_names] = parse_mat_dag(loaded);
    otherwise
        [dag, node_names] = parse_text_dag(source_file);
end

dag = logical(dag);
if isempty(node_names)
    node_names = arrayfun(@(i) sprintf('X%d', i), 1:size(dag, 1), 'UniformOutput', false);
end
end

function [data, node_names] = parse_mat_data(loaded)
node_names = {};
if isfield(loaded, 'node_names')
    node_names = cellstr(string(loaded.node_names(:)'));
elseif isfield(loaded, 'var_names')
    node_names = cellstr(string(loaded.var_names(:)'));
end

data_fields = {'continuous_data', 'data', 'X', 'observations', 'raw_data'};
for i = 1:numel(data_fields)
    if isfield(loaded, data_fields{i})
        data = loaded.(data_fields{i});
        return;
    end
end

vars = fieldnames(loaded);
for i = 1:numel(vars)
    value = loaded.(vars{i});
    if isnumeric(value) && ismatrix(value)
        data = value;
        return;
    end
end
error('No numeric observation matrix found in the MAT file.');
end

function [dag, node_names] = parse_mat_dag(loaded)
node_names = {};
if isfield(loaded, 'node_names')
    node_names = cellstr(string(loaded.node_names(:)'));
elseif isfield(loaded, 'var_names')
    node_names = cellstr(string(loaded.var_names(:)'));
end

dag_fields = {'true_dag', 'dag', 'adjacency', 'adj_matrix'};
for i = 1:numel(dag_fields)
    if isfield(loaded, dag_fields{i})
        dag = loaded.(dag_fields{i});
        return;
    end
end
error('No adjacency matrix found in the MAT DAG file.');
end

function [data, node_names] = parse_text_data(source_file)
[~, ~, ext] = fileparts(source_file);
delimiter = infer_delimiter(ext);
table_data = readtable(source_file, 'FileType', 'text', 'Delimiter', delimiter);

if width(table_data) > 1
    data = table2array(table_data);
    node_names = cellstr(string(table_data.Properties.VariableNames));
    if should_drop_index_column(data, node_names)
        data(:, 1) = [];
        node_names(1) = [];
    end
    data = data';
    return;
end

data = try_read_numeric_matrix(source_file, ext);
if isempty(data)
    error('Unable to parse TE observation file: %s', source_file);
end
node_names = {};
end

function [dag, node_names] = parse_text_dag(source_file)
[~, ~, ext] = fileparts(source_file);
delimiter = infer_delimiter(ext);
raw = readcell(source_file, 'FileType', 'text', 'Delimiter', delimiter);
raw = raw(~all(cellfun(@(x) (isstring(x) || ischar(x)) && isempty(strtrim(string(x))) || isempty(x), raw), 2), :);

if isempty(raw)
    error('Empty DAG file: %s', source_file);
end

if size(raw, 1) == size(raw, 2) && all(cellfun(@isnumeric, raw(:)))
    dag = logical(cell2mat(raw));
    node_names = {};
    return;
end

matrix_data = try_read_numeric_matrix(source_file, ext);
if ~isempty(matrix_data) && size(matrix_data, 1) == size(matrix_data, 2)
    dag = logical(matrix_data);
    node_names = {};
    return;
end

header_row = string(raw(1, 2:end));
if size(raw, 1) - 1 == numel(header_row) && all(cellfun(@(x) isnumeric(x) || islogical(x), raw(2:end, 2:end), 'UniformOutput', true), 'all')
    dag = logical(cell2mat(raw(2:end, 2:end)));
    node_names = cellstr(header_row);
    return;
end

if size(raw, 2) < 2
    error('Unsupported DAG text format: %s', source_file);
end

edges = raw;
if any(strcmpi(string(raw(1, :)), "source")) || any(strcmpi(string(raw(1, :)), "from"))
    edges = raw(2:end, :);
end
edge_sources = string(edges(:, 1));
edge_targets = string(edges(:, 2));
node_names = unique([edge_sources; edge_targets], 'stable')';
dag = false(numel(node_names));
for i = 1:numel(edge_sources)
    s = find(strcmp(node_names, edge_sources(i)), 1);
    t = find(strcmp(node_names, edge_targets(i)), 1);
    if ~isempty(s) && ~isempty(t)
        dag(s, t) = true;
    end
end
node_names = cellstr(node_names);
end

function delimiter = infer_delimiter(ext)
switch lower(ext)
    case '.tsv'
        delimiter = '\t';
    case '.txt'
        delimiter = ' ';
    otherwise
        delimiter = ',';
end
end

function tf = should_drop_index_column(data, node_names)
tf = false;
if isempty(data) || size(data, 2) < 2 || isempty(node_names)
    return;
end
first_col = data(:, 1);
if ~isnumeric(first_col) || any(isnan(first_col))
    return;
end
is_zero_based = isequal(first_col(:), (0:size(data, 1)-1)');
is_one_based = isequal(first_col(:), (1:size(data, 1))');
first_name = string(node_names{1});
name_looks_like_index = startsWith(lower(first_name), "var") || first_name == "" || first_name == "row";
tf = (is_zero_based || is_one_based) && name_looks_like_index;
end

function matrix_data = try_read_numeric_matrix(source_file, ext)
matrix_data = [];

try
    matrix_data = readmatrix(source_file);
catch
end
if is_valid_numeric_matrix(matrix_data)
    return;
end

delimiters = {};
switch lower(ext)
    case '.csv'
        delimiters = {',', ';'};
    case '.tsv'
        delimiters = {'\t'};
    case '.txt'
        delimiters = {' ', '\t', ',', ';'};
    otherwise
        delimiters = {',', '\t', ' ', ';'};
end

for i = 1:numel(delimiters)
    try
        matrix_data = readmatrix(source_file, 'Delimiter', delimiters{i});
    catch
        matrix_data = [];
    end
    if is_valid_numeric_matrix(matrix_data)
        return;
    end
end

matrix_data = [];
end

function tf = is_valid_numeric_matrix(matrix_data)
tf = isnumeric(matrix_data) && ~isempty(matrix_data) && ismatrix(matrix_data) && ...
    ~all(isnan(matrix_data), 'all');
end

function [aligned_data, node_names, aligned_dag] = align_te_data_and_dag(data, data_node_names, dag, dag_node_names)
if isempty(data_node_names) && isempty(dag_node_names)
    node_count = size(data, 1);
    node_names = arrayfun(@(i) sprintf('X%d', i), 1:node_count, 'UniformOutput', false);
    aligned_data = data;
    aligned_dag = dag;
    return;
end

if isempty(data_node_names)
    data_node_names = dag_node_names;
end
if isempty(dag_node_names)
    dag_node_names = data_node_names;
end

data_node_names = cellstr(string(data_node_names(:)'));
dag_node_names = cellstr(string(dag_node_names(:)'));

if numel(data_node_names) ~= size(data, 1)
    error('Observation node name count does not match data dimension.');
end
if numel(dag_node_names) ~= size(dag, 1)
    dag_node_names = arrayfun(@(i) sprintf('X%d', i), 1:size(dag, 1), 'UniformOutput', false);
end

[shared_names, data_idx, dag_idx] = intersect(data_node_names, dag_node_names, 'stable');
if isempty(shared_names)
    error('No overlapping node names between TE observations and the reference DAG.');
end

aligned_data = data(data_idx, :);
aligned_dag = dag(dag_idx, dag_idx);
node_names = shared_names;
end

function [states, edges] = quantile_discretize(values, state_count)
values = double(values(:)');
n = numel(values);
[sorted_values, order] = sort(values, 'ascend');
states = zeros(1, n);
states(order) = min(state_count, ceil((1:n) * state_count / n));
edges = zeros(1, max(0, state_count - 1));
for i = 1:(state_count - 1)
    edges(i) = sorted_values(max(1, floor(i * n / state_count)));
end
end
