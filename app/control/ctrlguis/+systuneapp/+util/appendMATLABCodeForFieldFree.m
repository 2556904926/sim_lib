function Text = appendMATLABCodeForFieldFree(Text,Free,BlockName, BlockType)
% Low level utility function to add MATLAB Code for Models Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

switch BlockType
    case 'tunableGain'
        VarNameFree = sprintf('%s.Gain.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
    case 'tunableTF'
        VarNameFree = sprintf('%s.Num.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Den.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
    case 'tunableSS'
        VarNameFree = sprintf('%s.A.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.B.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.C.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.D.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
    case 'tunablePID'
        VarNameFree = sprintf('%s.Kp.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Ki.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Kd.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Tf.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
    case 'tunablePID2'
        VarNameFree = sprintf('%s.Kp.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Ki.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Kd.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.Tf.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.b.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
        
        VarNameFree = sprintf('%s.c.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);
    case 'realp'
        VarNameFree = sprintf('%s.Free',BlockName);
        Text = controllib.internal.codegen.appendMATLABCode(Text,Free,VarNameFree);        
end
