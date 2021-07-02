function options = setVarArginOptions(optionsDefinition, options, varargin)
% utility for use with varargin arrow type function arguments

if ~isstruct(optionsDefinition)
    error('expected a structure for input argument ''optionsDefinition'' ');
end

% if not on input: first initialize the options structure and set to default:
if isempty(options)
    options = initialize(optionsDefinition);
elseif ~isequal(fieldnames(options), fieldnames(optionsDefinition))
    error('options and options definition do not match')
end


if ~isempty(varargin)
    % reset the fields required by the varargin argument
    options =  setRequired(options, optionsDefinition, varargin{:});
end
function options = setRequired(options, optionsDefinition, varargin)
opList = fieldnames(optionsDefinition);
for i=1:2:length(varargin)
    if length(varargin) < i+1
        error('Optional arguments must come as property/value pairs');
    end
    prop = varargin{i};
    if ~ischar(prop)
        error('Optional arguments must be identified using strings')
    end
    val  = varargin{i+1};
    % check if requested prop can be unambigeously identified in opList
    iProp = find(strncmpi(prop, opList, size(prop,2))) ;
    if length(iProp) ~= 1
        error(['Invalid option: ', prop,' (not defined or ambigeous).'])
    end
    prop = opList{iProp};
    if iscell(optionsDefinition.(prop)) && ~isempty(optionsDefinition.(prop))
        % Expect optionsDefinition.(prop) to be a cell array of strings
        % containing list of possible options as strings.
        % val must be a string as well.
        if ~ischar(val)
            error(['Value for option: ',prop,' must be a string.']);
        end
        % check if requested value is in the defined list
        iVal = find(strncmpi(val, optionsDefinition.(prop), size(val,2)));
        if length(iVal) == 1
            options.(prop) = char(optionsDefinition.(prop)(iVal));
        else
            error(['Invalid value for option: ', prop,' (''',val,''' not allowed or ambigeous).'])
        end
    else
        dType = class(optionsDefinition.(prop));
        if isa(val,dType)
            options.(prop) = val;
        else
            error(['Value for option: ', prop,' must be a ',dType]);
        end
        
        
    end
end
function ops = initialize(opdef)
% utility for varargin options
opList = fieldnames(opdef);
for i=1:length(opList)
    dftval = opdef.(opList{i});
    if iscell(dftval)&& ~isempty(dftval)
        ops.(opList{i}) = dftval{1};
    else
        ops.(opList{i}) = dftval;
    end
end
    
            

    
    
        