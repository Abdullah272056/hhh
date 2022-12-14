import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors.dart';
import '../api_service/api_service.dart';
import '../api_service/sharePreferenceDataSaveName.dart';
import '../model/individual_classroom_quiz_all_list_model.dart';
import '../view/HomePage.dart';

class ExamPageController extends GetxController {

  final shortQuestionNameController = TextEditingController().obs;
  final shortQuestionOptionNameController = TextEditingController().obs;
  var answerOption="".obs;
  var optionList = [].obs;

  Timer? timer;
  var startTxt = "00:00:00:00".obs;

  //if value 0 then exam finished or not start ,
  //if value 1 then exam is start running,
  var isExamStart = 0.obs;

  var userAccessToken = "".obs;

  var otpCountDownSecond = 0.obs;

  var isCountingStatus = false.obs;

  var instructionMessageText = "This is test instruction!".obs;


  var instructionMessageHtmlData="<p>There is no condition at yet!</p>".obs;


  var upcomingExamText = "Start Exam".obs;
  // var upcomingExamText = "Up Coming".obs;
  var getTime = "".obs;

  var hw_panel_id = "0".obs;
  var hw_panel_uid = "0".obs;

  var userName="".obs,fullName="".obs,userBatch="".obs,userBatchName="".obs,userType="".obs,userId="".obs,email="".obs;

  var classRoomQuizList=[].obs;

  //if question type 0 then none question show
  //if question type 1 then short question show
  //if question type 2 then mcq question show
  var questionType = 0.obs;

  // DateTime dt1 = DateTime.parse("2021-12-23 11:50:50") ;
  // DateTime dt2 = DateTime.parse("2021-12-23 11:40:10") ;

  var startDateTime= "".obs;
  var endDateTime = "".obs;
  var currentDateTime = "".obs;
  var endDateTimeUtc = "".obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    //getExamList();

    RetriveUserInfo();

    updateIsCountingStatus(false);
  }





  @override
  void dispose() {
    print('I am disposed');
   // timer!.cancel();
    super.dispose();

  }

  @override
  void onClose() {
    // timer!.cancel();
    super.onClose();
    print('I am closed');


  }

  // @override
  // void onInit() {
  //   // TODO: implement onInit
  //   super.onInit();
  //   getExamList();
  //   diffSecond(DateTime.parse("2021-12-23 11:50:50"),DateTime.parse("2021-12-23 11:40:10"));
  //   RetriveUserInfo();
  //   updateIsCountingStatus(false);
  // }


  //utc to local convert and date return
  String utcToLocalDate(String value){
    try{
      ///var dateFormat = DateFormat("dd-MM-yyyy hh:mm aa"); // you can change the format here
     /// var dateFormat = DateFormat("dd-MM-yyyy hh:mm"); // you can change the format here
      var dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss"); // you can change the format here
      var utcDate = dateFormat.format(DateTime.parse(value)); // pass the UTC time here
      var localDate = dateFormat.parse(utcDate, true).toLocal().toString();//convert local time

      // var dateFormat1 = DateFormat("hh:mm aa");
      var dateFormat2 = DateFormat("dd-MM-yyyy");

      String formattedTime = dateFormat.format(DateTime.parse(localDate));
      return formattedTime;
    }
    catch(Exception ){
      return "catch";
    }

  }

  ///input two time and difference between time and pass second with timer
  diffSecond(DateTime dt1,DateTime dt2,) {

    Duration diff = dt1.difference(dt2);

    if (diff.inSeconds > 0) {

      updateOtpCountDownSecond(diff.inSeconds);
      startTimer(diff.inSeconds);
    }else{
     // _showToast("elsse");
    }
  }


  ///time difference calculation(dt1-dt2)
 int timeDifferenceSecond(DateTime dt1,DateTime dt2,) {

    Duration diff = dt1.difference(dt2);
    return diff.inSeconds;
  }

  ///timer start if difference >0
  void startTimer(var second) {

    const oneSec = Duration(seconds: 1);


    timer = Timer.periodic(
      oneSec,
          (Timer timer) {

        if (second <= 0) {
          // _upcomingExamText = "Start Exam";
          updateUpcomingExamText("Start Exam");
          // updateIsExamStart(1);
          updateIsCountingStatus(true);
          updateIsExamStart(1);
         // _isCountingStatus = true;
          timer.cancel();
        }
        else {
          second--;
          updateStartTxt(_printDuration(Duration(seconds: second)));
         // _startTxt = _printDuration(Duration(seconds: second));
        }

      },
    );

  }

  ///timer cancel
  void cancelTimer(){
    timer?.cancel();
    updateStartTxt("00:00:00");

  }

  ///date format for user visible
  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitDay = twoDigits(duration.inDays.remainder(30));
    String twoDigitHour = twoDigits(duration.inHours.remainder(24));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitDay:$twoDigitHour:$twoDigitMinutes:$twoDigitSeconds";
  }

  updateUpcomingExamText(String value) {
    upcomingExamText(value);
  }
  updateStartTxt(String value) {
    startTxt(value);

  }
  updateIsCountingStatus(bool value) {
    isCountingStatus(value);
  }

  updateAnswerOption(String value) {
    answerOption(value);
  }
  updateOtpCountDownSecond(int value) {
    otpCountDownSecond(value);
  }

  updateGetTime(String value) {
    getTime(value);
  }
  updateIsExamStart(int value) {
    isExamStart(value);
  }


  updateHwPanelId(String value) {
    hw_panel_id(value);
  }
  updateHwPanelUId(String value) {
    hw_panel_uid(value);
  }


  ///time check startDateTime > currentDateTime
  _checkTime(){
    //startDateTime > currentDateTime
    if(timeDifferenceSecond(DateTime.parse(startDateTime.toString()),DateTime.parse(currentDateTime.toString()))>0){
      updateIsExamStart(0);
    }
    else{
      //endDateTime > currentDateTime
      if(timeDifferenceSecond(DateTime.parse(endDateTime.toString()),DateTime.parse(currentDateTime.toString()))>0){
        updateIsExamStart(1);
        updateUpcomingExamText("Start Exam");
      }else{
        updateIsExamStart(0);
      }
    }

    // timer.cancel();
    // timer?.cancel();
    diffSecond(DateTime.parse(startDateTime.toString()),DateTime.parse(currentDateTime.toString()));

    return;
  }

  // Future<void> main() async {
  //   [
  //     'time.google.com',
  //     'time.facebook.com',
  //     'time.euro.apple.com',
  //     'pool.ntp.org',
  //   ].forEach(_checkTime);
  // }
  //
  // Future<void> _checkTime(String lookupAddress) async {
  //   DateTime _myTime;
  //   DateTime _ntpTime;
  //
  //   /// Or you could get NTP current (It will call DateTime.now() and add NTP offset to it)
  //   _myTime = DateTime.now();
  //
  //   /// Or get NTP offset (in milliseconds) and add it yourself
  //   final int offset = await NTP.getNtpOffset(
  //       localTime: _myTime, lookUpAddress: lookupAddress);
  //
  //   _ntpTime = _myTime.add(Duration(milliseconds: offset));
  //
  //   print('\n==== $lookupAddress ====');
  //   print('My time: $_myTime');
  //   print('NTP time: $_ntpTime');
  //   print('Difference: ${_myTime.difference(_ntpTime).inMilliseconds}ms');
  //
  //   var devicedateUtc = DateTime.now().toUtc();
  //   var ntpdateUtc = _ntpTime.toUtc();
  //   updateCurrentDateTime(_ntpTime.toString());
  //
  //   // _showToast("startDateTime-currentDateTime: "+timeDifferenceSecond(DateTime.parse(startDateTime.toString()),DateTime.parse(currentDateTime.toString())).toString());
  //   //startDateTime > currentDateTime
  //   if(timeDifferenceSecond(DateTime.parse(startDateTime.toString()),DateTime.parse(currentDateTime.toString()))>0){
  //     updateIsExamStart(0);
  //   }else{
  //     //endDateTime > currentDateTime
  //     if(timeDifferenceSecond(DateTime.parse(endDateTime.toString()),DateTime.parse(currentDateTime.toString()))>0){
  //       updateIsExamStart(1);
  //       updateUpcomingExamText("Start Exam");
  //     }else{
  //       updateIsExamStart(0);
  //     }
  //   }
  //
  //   diffSecond(DateTime.parse(startDateTime.toString()),DateTime.parse(currentDateTime.toString()));
  //   updateGetTime(
  //       'Device time: $_myTime' +
  //           '\nNtp time: $_ntpTime' +
  //           '\nDevice utc: $devicedateUtc' +
  //           '\nNtp utc: $ntpdateUtc'
  //
  //   );
  //
  //   // setState(() {
  //   //   // _showToast(' $_myTime');
  //   //   getTime = 'Device time: $_myTime' +
  //   //       '\nNtp time: $_ntpTime' +
  //   //       '\nDevice utc: $devicedateUtc' +
  //   //       '\nNtp utc: $ntpdateUtc';
  //   // });
  //
  //   return;
  // }

  void updateClassRoomQuizList(List<QuizInfo> newList){
    classRoomQuizList=newList as RxList;
  }


 //get All Join Class room list
 void getStudentAllJoinClassroomList({required String hwPanelId,required String hwPanelUId}) async{
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        try {
          var response = await put(
            // Uri.parse('http://192.168.1.4:8000/api/individual-classroom-quiz-all-list/$classRoomId/'),
            // Uri.parse('http://192.168.1.4:8000/api/individual-classroom-quiz-all-list/$classRoomId/'),
              Uri.parse('$BASE_URL_EXAM_PANNEL$SUB_URL_API_GET_ALL_CLASS_ROOM_LIST$hwPanelId/'),
              body: {
                'uid':"$hwPanelUId"
              }
          );
         //  _showToast("${response.statusCode}");
          if (response.statusCode == 200) {

            // _showToast("success");
            var data = response.body;
            IndividualClassroomQuizAllListModel individualClassroomQuizAllListModel= individualClassroomQuizAllListModelFromJson(data);

            classRoomQuizList(individualClassroomQuizAllListModel.data[0].classroomInfo.quizInfo);





            for(int i=0;i<classRoomQuizList.length;i++){
              if(classRoomQuizList[i].isComplete==false){


                getTermsAndCondition(quizId: "${classRoomQuizList[0].quizTimeInfo[0].quizId}", accessToken: userAccessToken.value);


                updateStartDateTime(utcToLocalDate("${classRoomQuizList[0].quizTimeInfo[0].quizStartDate}"+
                    " ${classRoomQuizList[0].quizTimeInfo[0].quizStartTime}"));
                updateEndDateTime(utcToLocalDate("${classRoomQuizList[0].quizTimeInfo[0].quizEndDate}"+
                    " ${classRoomQuizList[0].quizTimeInfo[0].quizEndTime}"));
                updateEndDateTimeUtc("${classRoomQuizList[0].quizTimeInfo[0].quizEndDate}"+
                    " ${classRoomQuizList[0].quizTimeInfo[0].quizEndTime}");
                saveExamEndDate("${classRoomQuizList[0].quizTimeInfo[0].quizEndDate}"+
                    " ${classRoomQuizList[0].quizTimeInfo[0].quizEndTime}");
                updateCurrentDateTime(utcToLocalDate(individualClassroomQuizAllListModel.currentTimes.toString()));

                _checkTime();

                // updateCurrentDateTime("${classRoomQuizList[0].quizTimeInfo[0].quizEndDate}"+
                //     " ${classRoomQuizList[0].quizTimeInfo[0].quizEndTime}");

                // diffSecond(DateTime.parse(endDateTime.toString()),DateTime.parse(startDateTime.toString()));
                return;
              }
            }



            // _showToast(individualClassroomQuizAllListModel.data[0].classroomInfo.quizInfo.length.toString());
            // _showToast(classRoomQuizList.length.toString());

          }
          else {
            // Fluttertoast.cancel();

            log('data:'+response.body.toString());
            _showToast("failed try again!");

          }
        } catch (e) {
          // Fluttertoast.cancel();
        }
      }
    } on SocketException {

      Fluttertoast.cancel();
      // _showToast("No Internet Connection!");
    }
    //updateIsFirstLoadRunning(false);
  }


  ///terms or instruction api call
 void getTermsAndCondition({required String quizId,required String accessToken}) async{
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        try {
          var response = await get(
              // Uri.parse('https://exam.arenaclass.stream/api/individual-quiz-terms-and-condition/$quizId'),
              Uri.parse('$BASE_URL_EXAM_PANNEL$SUB_URL_API_GET_TERMS_AND_CONDITION$quizId'),
              headers: {
                // 'Authorization':'Token eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiNDg5MTAzMGUtZDMzOC00ODAwLWFhYzEtMDdjYWUwMWRmNGUzIiwiZXhwIjoxNjY5MDkzNzgwLCJpYXQiOjE2NjkwMDczODB9.KGzyxEKPkh9BiedU6EOM9BcobUbCgpnWgWDR4HN8p7k'
                'Authorization':'Token $accessToken'
              }
          );
           //_showToast("terms = ${response.statusCode}");
          if (response.statusCode == 200) {

            var data = jsonDecode(response.body);

            instructionMessageHtmlData(data["data"][0]["description"].toString());

          }
          else {
            // Fluttertoast.cancel();

            log('data:'+response.body.toString());
            _showToast("failed try again!");

          }
        } catch (e) {
          // Fluttertoast.cancel();
        }
      }
    } on SocketException {

      Fluttertoast.cancel();
      // _showToast("No Internet Connection!");
    }
    //updateIsFirstLoadRunning(false);
  }



  updateStartDateTime(String value) {
    startDateTime(value);

  }

  updateEndDateTime(String value) {
    endDateTime(value);
  }


  updateEndDateTimeUtc(String value) {
    endDateTimeUtc(value);
  }
  updateCurrentDateTime(String value) {
    currentDateTime(value);

  }

  //toast create
  _showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor:awsMixedColor,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  ///save dat with share pref
  void saveExamEndDate(String examEndDate) async {
    try {
      var storage =GetStorage();
      storage.write(pref_user_exam_end_time, examEndDate);


    } catch (e) {

    }


  }

  void goToHomePage() {
    onInit();
    Get.offAll(HomePageScreen());
  }


  ///get data from share pref
  void RetriveUserInfo() async {
    try {

      var storage =GetStorage();
      userName(storage.read(pref_user_name)??"");
      email(storage.read(pref_user_email)??"");
      fullName(storage.read(pref_full_name)??"");
      userBatch(storage.read(pref_user_batch)??"");
      userBatchName(storage.read(pref_user_batch_name)??"");
      userType(storage.read(pref_user_type)??"");
      userId(storage.read(pref_user_id)??"");


      userAccessToken(storage.read(exam_panel_user_access_token)??"");

      storage.read(exam_pannel_pref_user_uid);
      storage.read(exam_panel_pref_user_id);

      updateHwPanelId(storage.read(exam_panel_pref_user_id));
      updateHwPanelUId(storage.read(exam_pannel_pref_user_uid));

      ///call all join class room list
      getStudentAllJoinClassroomList(
          hwPanelId: storage.read( exam_panel_pref_user_id).toString(),
          hwPanelUId: storage.read(exam_pannel_pref_user_uid).toString());

    } catch (e) {

      //code


    }


    // sharedPreferences.setString(pref_user_UUID, userInfo['data']["user_name"].toString());
    // sharedPreferences.setBool(pref_login_firstTime, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_cartID, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_county, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_city, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_state, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_nid, userInfo['data']["user_name"].toString());
    // sharedPreferences.setString(pref_user_nid, userInfo['data']["user_name"].toString());


  }

}