function out = utPIDappendSignals(ts1, ts2)

if isnan(ts1.TimeInfo.Increment) | isnan(ts2.TimeInfo.Increment)
    error('Invalid sample time');
end
if ts1.TimeInfo.Increment ~= ts2.TimeInfo.Increment
    error('Invalid inputs');
end

sampletime = ts1.TimeInfo.Increment;

ts2.Time = ts2.Time + ts1.Time(end);
ts1 = delsample(ts1,'Index',ts1.Length);
out = append(ts1,ts2);

end