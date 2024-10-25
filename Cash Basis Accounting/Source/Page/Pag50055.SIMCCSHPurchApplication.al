page 50055 "SLGI CSH Purch Application"
{
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Enter Application Date';

    layout
    {
        area(Content)
        {
            group(Application)
            {
                field(ApplicationDate; ApplicationDate)
                {
                    ApplicationArea = All;
                    Caption = 'Application Date';
                    ToolTip = 'Enter the application date for the posted purchase document';
                }
            }
        }
    }

    var
        ApplicationDate: Date;

    procedure SetVars(AppDate: Date)
    begin
        ApplicationDate := AppDate;
    end;

    procedure GetVars(var AppDate: Date)
    begin
        AppDate := ApplicationDate;
    end;
}