unit TwitterCore;

interface

uses
  System.Messaging,
  System.SysUtils,
  FMX.Dialogs,
  FMX.Types,
  FMX.Controls,


{$IFDEF IOS}
  iOSApi.Twitter,
  iOSapi.UIKit,
  iOSapi.Foundation,
  iOSApi.TWTRSession,
  iOSApi.TWTRAPIClient,
  iOSApi.TWTRUser,

  FMX.Platform,
  FMX.Platform.iOS,
  FMX.Helpers.iOS,

  Macapi.Helpers,
{$ENDIF}

{$IFDEF ANDROID}
  Androidapi.JNI.classes,
  Androidapi.JNI.my_twitter_user,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.my_twitter_UserInformation,
  FMX.Helpers.Android,
  Androidapi.Helpers,
{$ENDIF}

  uBaseNativeView,
//  uAndroidViewController,
  System.Classes;

type
  {$IFDEF ANDROID}
  TWitter=class;
  //TWitter授权返回
  TJMyTwitterSessionCallback_MyCallBackTwitterSession=class(TJavaLocal,JMyTwitterSessionCallback_MyCallBackTwitterSession)
  public
    { Property Methods }
    FUserID:Integer;
    FUserName:String;
    FToken:JTwitterAuthToken;
    { methods }
    //授权成功
    procedure success(P1: JResult; P2: Int64; P3: JString; P4: JTwitterAuthToken); cdecl;
    //授权失败
    procedure failure; cdecl;
  public
    FTwitter:TWitter;
    constructor Create(ATwitter:TWitter);
    { Property }
  end;

  TJMyCallUser_GetMyInfo = class(TJavaLocal,JMyCallUser_GetMyInfo)
  public
    { Property Methods }

    { methods }
    procedure success(P1: JUser); cdecl;
    procedure failure; cdecl;
  public
    FTwitter:TWitter;
    constructor Create(ATwitter:TWitter);
  end;
  {$ENDIF}




  TWitter=class(TSkinNativeView)
  public class var
    FKey:String;
    FSecret:String;
    {$IFDEF ANDROID}
    FTwitterConfigBuilder:JTwitterConfig_Builder;
    FTwitterAuthConfig:JTwitterAuthConfig;
    FTwitterConfig:JTwitterConfig;
    {$ENDIF}

    //初始化
    class procedure initialize;
  protected
    {$IFDEF ANDROID}
    FLoginButton:JTwitterLoginButton;
    {$ENDIF}
    {$IFDEF ANDROID}
    FJTwitterSession:JTwitterSession;
    FMyCallBackTwitterSession:TJMyTwitterSessionCallback_MyCallBackTwitterSession;
    FMyCallBackUserInfo:TJMyCallUser_GetMyInfo;
    FCallbackTwitterSession:JMyTwitterSessionCallback;
    FGetMyInfo:JMyCallUser;
    FUser:JUSer;
//    FAndroidViewController:TAndroidViewController;
   {$ENDIF}
    {$IFDEF ANDROID}
    FMessageSubscriptionID: Integer;
    //启动扫描结果处理的定时器
    function OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent): Boolean;
    procedure HandleActivityMessage(const Sender: TObject; const M: TMessage);
    {$ENDIF}
    //创建原生控件
    function CreateNativeView: TNativeView; override;
  public
    {$IFDEF IOS}
    FApplicationEventService:IFMXApplicationEventService;
    function OnApplicationEventHandler(AAppEvent: TApplicationEvent; AContext: TObject):Boolean;

    procedure DoLoginCompletion(session:TWTRSession;error:NSError);

    procedure DoGetTwitterUserInfo(twitteruser:TWTRUser;error:NSError);
    {$ENDIF}
  public

    FUserName:String;
    FUserID:Integer;
    FUserProfileImageUrl:String;
    FUserSereenName:String;
    FUserProfileImageUrlHttps:String;

    FToken:String;

    //获取用户信息完成的事件
    FOnGetUserInfoComplete:TNotifyEvent;

    //手动登录
    procedure ManualLogin;//(AControl:TControl);

    //获取用户信息
    procedure GetTwitterUserInfo;

  end;

implementation


{ TWitter }

{$IFDEF IOS}
procedure TWitter.DoGetTwitterUserInfo(twitteruser: TWTRUser; error: NSError);
begin
  Self.FUserName:=NSStrToStr(twitteruser.name);
  Self.FUserID:=StrToInt(NSStrToStr(twitteruser.userID));
  Self.FUserProfileImageUrl:=NSStrToStr(twitteruser.profileImageURL);
end;
{$ENDIF}

{$IFDEF IOS}
procedure TWitter.DoLoginCompletion(session: TWTRSession; error: NSError);
begin

  Self.FUserID:=StrToInt(NSStrToStr(session.userID));;
  Self.FToken:=NSStrToStr(session.authToken);
end;
{$ENDIF}

function TWitter.CreateNativeView: TNativeView;
begin
  {$IFDEF ANDROID}
  FMessageSubscriptionID := TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification,HandleActivityMessage);

  FLoginButton:=TJTwitterLoginButton.JavaClass.init(TAndroidHelper.Context);
  Result:=FLoginButton;


  //授权登录
  FCallbackTwitterSession:=TJMyTwitterSessionCallback.JavaClass.init;
  FMyCallBackTwitterSession:=TJMyTwitterSessionCallback_MyCallBackTwitterSession.Create(Self);

  FCallbackTwitterSession.setmytwittersession(FMyCallBackTwitterSession);

  FLoginButton.setCallback(FCallbackTwitterSession.GetCallBack);


  {$ENDIF ANDROID}

end;

procedure TWitter.GetTwitterUserInfo;
begin
  FMX.Types.Log.d('OrangeUI TWitter.GetTwitterUserInfo Begin');

 {$IFDEF ANDROID}
  FJTwitterSession:=TJTwitterSession.JavaClass.init(FMyCallBackTwitterSession.FToken,
                                                    FMyCallBackTwitterSession.FUserID,
                                                    StringToJString(FMyCallBackTwitterSession.FUserName));
  FGetMyInfo:=TJMyCallUser.Create;

  FMyCallBackUserInfo:=TJMyCallUser_GetMyInfo.Create(Self);
  FGetMyInfo.setmyuserinfo(FMyCallBackUserInfo);

  FGetMyInfo.requestUserInfo(TAndroidHelper.Context,FJTwitterSession);

 {$ENDIF}

 {$IFDEF IOS}
 TTWTRAPIClient.OCClass.clientWithCurrentUser.loadUserWithIDcompletion(StrToNSStr(Self.FToken),DoGetTwitterUserInfo);
 {$ENDIF}

  FMX.Types.Log.d('OrangeUI TWitter.GetTwitterUserInfo End');
end;

 {$IFDEF ANDROID}
procedure TWitter.HandleActivityMessage(const Sender: TObject;
  const M: TMessage);
begin

  FMX.Types.Log.d('OrangeUI TWitter.HandleActivityMessage Begin');

  if M is TMessageResultNotification then
  begin
    OnActivityResult(TMessageResultNotification(M).RequestCode,
                      TMessageResultNotification(M).ResultCode,
                      TMessageResultNotification(M).Value);

  end;


  FMX.Types.Log.d('OrangeUI TWitter.HandleActivityMessage End');

end;
{$ENDIF}

class procedure TWitter.initialize;
begin
  FMX.Types.Log.d('OrangeUI TWitter initialize Begin');

  {$IFDEF ANDROID}
  FTwitterConfigBuilder:=TJTwitterConfig_Builder.JavaClass.init(TAndroidHelper.Context);
  FTwitterAuthConfig:=TJTwitterAuthConfig.JavaClass.init(StringToJString(FKey),StringToJString(FSecret));
  FTwitterConfig:=FTwitterConfigBuilder.
                                        twitterAuthConfig(FTwitterAuthConfig)
                                        .debug(True)
                                        .build;


  TJTwitter.JavaClass.initialize(FTwitterConfig);
  {$ENDIF}


  {$IFDEF IOS}
  TTwitter.OCClass.sharedInstance.startWithConsumerKeyconsumerSecret(
                                                                    StrToNSStr(FKey),
                                                                    StrtoNSStr(FSecret));
  {$ENDIF}


  FMX.Types.Log.d('OrangeUI TWitter initialize End');
end;

{$IFDEF ANDROID}
function TWitter.OnActivityResult(RequestCode, ResultCode: Integer;
  Data: JIntent): Boolean;
begin

  TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FMessageSubscriptionID);
  FMessageSubscriptionID := 0;

  if FLoginButton<>nil then
  begin
    FLoginButton.onActivityResult(requestCode, resultCode, data);
  end;


end;
{$ENDIF}

{$IFDEF IOS}
function TWitter.OnApplicationEventHandler(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin

  case AAppEvent of
    TApplicationEvent.OpenURL:
    begin
      Result:=False;
      if TTwitter.OCClass.sharedInstance.applicationopenURLoptions(
        SharedApplication,
        StrToNSUrl(TiOSOpenApplicationContext(AContext).URL),
        TiOSOpenApplicationContext(AContext).Context
        ) then
      begin
        Result:=True;
      end;
    end;
  end;

end;
{$ENDIF}


procedure TWitter.ManualLogin;//(AControl:TControl);
begin
  FMX.Types.Log.d('OrangeUI TWitter Login Begin');

  {$IFDEF ANDROID}
//  CallInUIThread(
//  procedure
//  begin
//    FLoginButton:=TJTwitterLoginButton.JavaClass.init(TAndroidHelper.Context);


//    //授权登录
//    FCallbackTwitterSession:=TJMyTwitterSessionCallback.JavaClass.init;
//    FMyCallBackTwitterSession:=TJMyTwitterSessionCallback_MyCallBackTwitterSession.Create(Self);
//
//    FCallbackTwitterSession.setmytwittersession(FMyCallBackTwitterSession);
//
//    FLoginButton.setCallback(FCallbackTwitterSession.GetCallBack);



//    FAndroidViewController:=TAndroidViewController.Create(AControl,TJView.Wrap((FLoginButton as ILocalObject).GetObjectID));
//    FAndroidViewController.Show;
//    FAndroidViewController.UpdateContentFromControl;
//
//    FMX.Types.Log.d('OrangeUI FAndroidViewController Show');


//  end);
  {$ENDIF}



  {$IFDEF IOS}
  //登录
  TTWitter.OCClass.sharedInstance.logInWithCompletion(Self.DoLoginCompletion);
  {$ENDIF}



  FMX.Types.Log.d('OrangeUI TWitter Login End');
end;

{$IFDEF ANDROID}
{ TJMyCallUser_GetMyInfo }

constructor TJMyCallUser_GetMyInfo.Create(ATwitter: TWitter);
begin
  Inherited Create;
  Self.FTwitter:=ATwitter;
end;

procedure TJMyCallUser_GetMyInfo.failure;
begin
  FMX.Types.Log.d('OrangeUI TJMyCallUser_GetMyInfo failure');
end;

procedure TJMyCallUser_GetMyInfo.success(P1: JUser);
begin
  FMX.Types.Log.d('OrangeUI TJMyCallUser_GetMyInfo success');

  Self.FTwitter.FUser:=P1;
  Self.FTwitter.FUserName:=JStringToString(P1.name);
  Self.FTwitter.FUserID:=P1.id;
  Self.FTwitter.FUserProfileImageUrl:=JStringToString(P1.profileImageUrl);
  Self.FTwitter.FUserSereenName:=JStringToString(P1.screenName);
  Self.FTwitter.FUserProfileImageUrlHttps:=JStringToString(P1.profileImageUrlHttps);

  if Assigned(FTwitter.FOnGetUserInfoComplete) then
  begin
    FTwitter.FOnGetUserInfoComplete(FTwitter);
  end;
end;
{$ENDIF}

{$IFDEF ANDROID}
{ TJMyTwitterSessionCallback_MyCallBackTwitterSession }

constructor TJMyTwitterSessionCallback_MyCallBackTwitterSession.Create(
  ATwitter: TWitter);
begin
  Inherited Create;
  Self.FTwitter:=ATwitter;
end;

procedure TJMyTwitterSessionCallback_MyCallBackTwitterSession.failure;
begin
  FMX.Types.Log.d('OrangeUI TJMyTwitterSessionCallback_MyCallBackTwitterSession failure');
end;

procedure TJMyTwitterSessionCallback_MyCallBackTwitterSession.success(
  P1: JResult; P2: Int64; P3: JString; P4: JTwitterAuthToken);
begin
  FMX.Types.Log.d('OrangeUI TJMyTwitterSessionCallback_MyCallBackTwitterSession UserName:'+JStringToString(P3));
  FMX.Types.Log.d('OrangeUI TJMyTwitterSessionCallback_MyCallBackTwitterSession token:'+JStringToString(P4.token));
  FMX.Types.Log.d('OrangeUI TJMyTwitterSessionCallback_MyCallBackTwitterSession secret:'+JStringToString(P4.secret));

//    { Property }
//    property token: JString read _Gettoken write _Settoken;
//    property secret: JString read _Getsecret write _Setsecret;

  Self.FUserName:=JStringToString(P3);
  Self.FToken:=P4;
  Self.FUserID:=P2;
  Self.FTwitter.FToken:=JStringToString(P4.token);
end;
{$ENDIF}

end.
