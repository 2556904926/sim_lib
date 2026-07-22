function Expression = createExpressionForZPKModel(Model)
% Static function to compute expression given a dynamic system
if isnumeric(Model)
    Expression = ['zpk(' num2str(Model) ')'];
elseif isa(Model,'lti')
    ValueZPK = zpk(Model);
    if isempty(ValueZPK.z{:})
        z = '[],';
    elseif numel(ValueZPK.z{:}) == 1
        z = [num2str(ValueZPK.z{:}), ','];
    else
        z = [mat2str(ValueZPK.z{:}), ','];
    end
    
    if isempty(ValueZPK.p{:})
        p = '[],';
    elseif numel(ValueZPK.p{:}) == 1
        p = [num2str(ValueZPK.p{:}), ','];
    else
        p = [mat2str(ValueZPK.p{:}), ','];
    end
    
    if isempty(ValueZPK.k(:))
        k = '[]';
    elseif numel(ValueZPK.k(:)) == 1
        k = num2str(ValueZPK.k(:));
    else
        k = mat2str(ValueZPK.k(:));
    end
    
    Expression = ['zpk(', z,p,k ,')'];
end
end