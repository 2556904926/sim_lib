function BS = randomStart(T,N)
%randomStart   Generates N randomized initial values for tunable blocks.
%
%   BS = randomStart(T,N) returns an N-by-1 struct array BS whose fields
%   are the tunable blocks of T with randomly generated values for their
%   tunable parameters. Use
%
%     Tj = setBlockValue(T,BS(j))
%
%   to initialize T with the j-th set of values.
%
%   See also systune.

%   Copyright 2019 The MathWorks, Inc.

% Eliminate non-tunable blocks and sort block by names for consistency with
% getTuningData
BS = T.Blocks;
BN = fieldnames(BS);  % block names
BV = struct2cell(BS); % block param
isP = cellfun(@isParametric,BV);
BN = BN(isP);
BV = BV(isP);
[BN,is] = sort(BN);
BV = BV(is,ones(N,1));

% Randomize block values
for ct=1:numel(BN)
   blk = BV{ct,1};
   x = randp(blk,N,'free');
   for j=1:N
      BV{ct,j} = setp(BV{ct,j},x(:,j),'free');
   end
end
   
% Construct output   
BS = cell2struct(BV,BN,1);