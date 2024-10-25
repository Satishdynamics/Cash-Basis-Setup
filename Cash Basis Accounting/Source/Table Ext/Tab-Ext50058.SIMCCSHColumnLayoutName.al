tableextension 50058 "SLGI CSH Column Layout Name" extends "Column Layout Name"
{
    fields
    {
        field(70163480; "SLGI CSH Cash Basis"; Boolean)
        {
            Caption = 'Cash Basis';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AnalysisView: Record "Analysis View";
            begin
                if AnalysisView.Get("Analysis View Name") then
                    if AnalysisView."SLGI CSH Cash Basis" <> "SLGI CSH Cash Basis" then
                        Error('Analysis view %1 must match the cash basis field', "Analysis View Name");
            end;
        }
    }
}