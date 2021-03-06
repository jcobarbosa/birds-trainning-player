import 'dart:async';

import 'package:audio_manager/audio_manager.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';

void main() => runApp(BirdsTrainningApp());

class BirdsTrainningApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treinador de Canto',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final ScheduleList list = ScheduleList();
  final LocalStorage storage = LocalStorage('bird_trainning_player_app');

  //arquivos de áudio
  final Map<String, AudioInfo> playList = {
    "cantos01.wav": AudioInfo("assets/cantos01.wav", title: "cantos01.wav", desc: "Cantos 01", coverUrl: "assets/cover.png"),
    // "cantos02.wav": AudioInfo("assets/cantos02.wav", title: "cantos02.wav", desc: "Cantos 02", coverUrl: "assets/cover.png"),
    // "cantos03.wav": AudioInfo("assets/cantos03.wav", title: "cantos03.wav", desc: "Cantos 03", coverUrl: "assets/cover.png"),
    // "cantos04.wav": AudioInfo("assets/cantos04.wav", title: "cantos04.wav", desc: "Cantos 04", coverUrl: "assets/cover.png"),
    "musica01.wav": AudioInfo("assets/musica01.wav", title: "musica01.wav", desc: "Música 01", coverUrl: "assets/cover.png"),
    // "musica02.wav": AudioInfo("assets/musica02.wav", title: "musica02.wav", desc: "Música 02", coverUrl: "assets/cover.png"),
    // "musica03.wav": AudioInfo("assets/musica03.wav", title: "musica03.wav", desc: "Música 03", coverUrl: "assets/cover.png"),
    // "musica04.wav": AudioInfo("assets/musica04.wav", title: "musica04.wav", desc: "Música 04", coverUrl: "assets/cover.png"),
  };

  bool initialized = false;
  Timer? timer;
  Schedule? _scheduleActive;
  late double _sliderVolume;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scheduleActive = null;
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => verifyActiveSchedule());
    });
  }

  void setUpdatePlayList(Set<AudioInfo?> audioInfos) {

    if (audioInfos != null && audioInfos.isNotEmpty) {
      List<AudioInfo> _list = List.empty(growable: true);
      for (var element in audioInfos) {
        if (element != null) {
          _list.add(element);
        }
      }

      AudioManager.instance.audioList = _list;
      AudioManager.instance.intercepter = true;
      AudioManager.instance.play(auto: true);
      AudioManager.instance.onEvents((events, args) {
        switch (events) {
          case AudioManagerEvents.ready:
            print("ready to play");
            _sliderVolume = AudioManager.instance.volume;
            break;
          case AudioManagerEvents.ended:
            AudioManager.instance.next();
            break;
          case AudioManagerEvents.volumeChange:
            _sliderVolume = AudioManager.instance.volume;
            setState(() {});
            break;
        }
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
            children: [
              const Text("Treinador de Canto"),
              Icon(Icons.music_note),
              Visibility(
                child: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        AudioManager.instance.playOrPause();
                        if (_scheduleActive == null) {
                          const snackBar = SnackBar(content: Text('Sem playlist'), duration: Duration(seconds: 2));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      });
                    }
                ),
                visible: !AudioManager.instance.isPlaying && _scheduleActive != null,
              ),
              Visibility(
                child: IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: () {
                      setState(() {
                        AudioManager.instance.playOrPause();
                      });
                    }
                ),
                visible: AudioManager.instance.isPlaying && _scheduleActive != null,
              ),
              Visibility(
                child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      if (list.schedules.isNotEmpty) {
                        showDialog(
                            context: context,
                            builder: (context) => const ConfirmDialog()
                        ).then((confirmation) {
                          if (confirmation) {
                            setState(() {
                              storage.setItem('schedules', null);
                              list.schedules = [];
                              AudioManager.instance.stop();
                              _scheduleActive = null;
                            });
                          }
                        });
                      } else {
                        const snackBar = SnackBar(content: Text('Sem agendamentos para excluir'), duration: Duration(seconds: 2));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    }
                ),
                visible: list.schedules.isNotEmpty,
              )
            ]
        ),
      ),
      body: Container(
          padding: const EdgeInsets.all(10.0),
          constraints: const BoxConstraints.expand(),
          child: FutureBuilder(
            future: storage.ready,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!initialized) {
                var schedules = storage.getItem('schedules');

                if (schedules != null) {
                  list.schedules = List<Schedule>
                      .from((schedules as List)
                      .map((_schedule) {
                    var schedule = Schedule(
                      id: _schedule['id'],
                      start: _schedule['start'],
                      end: _schedule['end'],
                    );
                    if (_schedule['songs'] != null && _schedule['songs'].isNotEmpty) {
                      List<dynamic> songsList= _schedule['songs'];
                      Set<AudioInfo?> _songs = {};
                      for (var audioInfo in songsList) {
                        if (audioInfo != null) {
                          var _audioInfo = AudioInfo.fromJson(audioInfo);
                          _songs.add(_audioInfo);
                        }
                      }
                      schedule.songs = _songs;
                    }
                    return schedule;
                  },
                  ),
                  );
                } else {
                  list.schedules = List.empty(growable: true);
                }

                initialized = true;
              }

              List<Widget> widgets = List.empty(growable: true);

              if (list != null && list.schedules.isNotEmpty) {
                widgets = list.schedules.map((scheduleListTile) {
                  return ListTile(
                    title:
                    Row(children: [
                      Text('Inicia às ' + scheduleListTile.start + ' e toca até ' + scheduleListTile.end),
                    ]
                    ),
                    selectedTileColor: const Color.fromRGBO(255, 255, 204, 0.6),
                    selected: scheduleListTile.selected,
                    onLongPress: () {
                      setState(() {
                        Schedule? scheduleFound;

                        for (var scheduleFromList in list.schedules) {
                          if (scheduleFromList.id == scheduleListTile.id) {
                            scheduleFound = scheduleFromList;
                            break;
                          }
                        }

                        if (scheduleFound != null) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertAddSchedule(scheduleEdit: scheduleFound, playList: playList),
                          ).then((schedule) {
                            if (schedule != null && _isValidScheduleTime(schedule)) {
                              for (var scheduleFromList in list.schedules) {
                                if (scheduleFromList.id == schedule.id) {
                                  scheduleFromList = schedule;
                                }
                              }
                              _saveToStorage();
                            }
                          });
                        }
                      }
                      );
                    },
                  );
                }).toList();
              }

              return Column(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: widgets,
                      itemExtent: 50.0,
                    ),
                  ),
                ],
              );
            },
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertAddSchedule(playList: playList)
          ).then((schedule) {
            if (schedule != null && _isValidScheduleTime(schedule)) {
              _addScheduleModel(schedule);
            }
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  _addScheduleModel(final Schedule schedule) {
    setState(() {
      list.schedules.add(schedule);
      _saveToStorage();
    });
  }

  _saveToStorage() {
    setState(() {
      storage.setItem('schedules', list.toJSONEncodable());
    });
  }

  verifyActiveSchedule() {
    var itemFound = false;
    var itemDisabled = false;

    var formatter = new DateFormat('Hm');
    String currentTimeString = formatter.format(new DateTime.now());
    int currentTime = int.parse(currentTimeString.replaceAll(':', ''));

    if (list.schedules != null && list.schedules.isNotEmpty) {
      for (Schedule _schedule in list.schedules) {
        setState(() {
          var isToSelect = currentTime >= int.parse(_schedule.start.replaceAll(':', '')) &&
              currentTime < int.parse(_schedule.end.replaceAll(':', ''));

          if (_schedule == _scheduleActive && _scheduleActive?.selected == true && !isToSelect) {
            AudioManager.instance.stop();
          }

          if (_schedule.selected && !isToSelect) {
            itemDisabled = true;
          }

          _schedule.selected = isToSelect;

          if (_schedule.selected && _schedule != _scheduleActive) {
            setState(() {
              _scheduleActive = _schedule;
              itemFound = true;
              setUpdatePlayList(_schedule.songs);
            });
          }
        });
      }

      if (!itemFound && itemDisabled) {
        setState(() {
          _scheduleActive = null;
        });
      }
    }
  }

  bool _isValidScheduleTime(Schedule scheduleToValid) {
    var isValid = true;
    var start = int.parse(scheduleToValid.start.replaceAll(':', ''));
    var end = int.parse(scheduleToValid.end.replaceAll(':', ''));

    list.schedules.forEach((scheduleFromList) {
      var startCompare = int.parse(scheduleFromList.start.replaceAll(':', ''));
      var endCompare = int.parse(scheduleFromList.end.replaceAll(':', ''));

      // if (start > startCompare && start <= endCompare) {
      //   isValid = false;
      //   print('valida1');
      //   return;
      // }
      //
      // if (end > startCompare && end <= endCompare) {
      //   isValid = false;
      //   print('valida2');
      //   return;
      // }

      if (start >= startCompare && end <= endCompare) {
        isValid = false;
        return;
      }
    });

    if (!isValid) {
      var message = 'Os horários escolhidos ('+scheduleToValid.start+' - '+scheduleToValid.end+') sobrepõem um agendamento já existente.';
      var snackBar = SnackBar(content: Text(message), duration: Duration(seconds: 5));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return isValid;
  }
}


class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({Key? key}): super(key: key);

  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Apagar agendamentos"),
      content: const Text(
          "Tem certeza de que deseja apagar todos os agendamentos?"),
      actions: [
        TextButton(
          child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: const Text("Confirmar", style: TextStyle(color: Colors.blue)),
          onPressed: () {
            Navigator.pop(context, true);
          },
        )
      ],
    );
  }
}

class AlertAddSchedule extends StatefulWidget {
  const AlertAddSchedule({Key? key, this.scheduleEdit, required this.playList}): super(key: key);

  final Map<String, AudioInfo> playList;
  final Schedule? scheduleEdit;

  @override
  _AlertAddScheduleState createState() => _AlertAddScheduleState();
}

class _AlertAddScheduleState extends State<AlertAddSchedule> {

  TextEditingController controllerStart = TextEditingController();
  TextEditingController controllerEnd = TextEditingController();
  Set<String> _mapOfSongs = {};
  Set<String> get mapOfSongs => _mapOfSongs;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState(){
    super.initState();

    if (widget.scheduleEdit != null) {
      controllerStart = TextEditingController()..text = widget.scheduleEdit!.start;
      controllerEnd = TextEditingController()..text = widget.scheduleEdit!.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Agendamentos"),
      content: Container(
        constraints: const BoxConstraints.tightForFinite(),
        child: Form(
            key: _formKey,
            child: Column(
                children: [
                  // DatePickerDialog(
                  //   initialDate: initialDate,
                  //   firstDate: firstDate,
                  //   lastDate: lastDate,
                  //   currentDate: currentDate,
                  //   initialEntryMode: initialEntryMode,
                  //   selectableDayPredicate: selectableDayPredicate,
                  //   helpText: helpText,
                  //   cancelText: cancelText,
                  //   confirmText: confirmText,
                  //   initialCalendarMode: DatePickerMode.day,
                  //   errorInvalidText: 'Horário inálido',
                  //   fieldHintText: 'Hórario de Início',
                  //   fieldLabelText: 'Inicio',
                  // )
                  TextFormField(
                    controller: controllerStart,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.lock_clock),
                        hintText: '00:00',
                        labelText: 'Início'
                    ),
                    maxLength: 5,
                    keyboardType: TextInputType.number,
                    onTap: () => _selectTime(context, controllerStart),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputMask(mask: '99:99', reverse: false)
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty || _isTimeInvalid(value)) {
                        return 'Horário inválido!';
                      }
                      return null;
                    }, // Only numbers can be entered // Only numbers can be entered
                  ),
                  TextFormField(
                    controller: controllerEnd,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.lock_clock),
                      hintText: '00:00',
                      labelText: 'Término',
                    ),
                    maxLength: 5,
                    keyboardType: TextInputType.number,
                    onTap: () => _selectTime(context, controllerEnd),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputMask(mask: '99:99', reverse: false)
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty || _isTimeInvalid(value)) {
                        return 'Horário inválido!';
                      }
                      return null;
                    },
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: CheckboxListTileDialog(
                              scheduleEdit: widget.scheduleEdit,
                              playList: widget.playList,
                              mapOfSongs: _mapOfSongs
                          )
                      )
                  )
                ]
            )
        ),
      ),

      actions: [
        TextButton(
          child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          onPressed: () {
            setState(() {
              Navigator.pop(context);
            });
          },
        ),
        TextButton(
            child: const Text("Salvar", style: TextStyle(color: Colors.blue)),
            onPressed: () {
              setState(() {
                if (_formKey.currentState!.validate()) {

                  Schedule? schedule = widget.scheduleEdit;

                  if (schedule == null) {
                    schedule = Schedule(id: DateTime.now().millisecondsSinceEpoch, start: controllerStart.value.text, end: controllerEnd.value.text);
                  } else {
                    schedule.start = controllerStart.value.text;
                    schedule.end = controllerEnd.value.text;
                  }

                  if (_mapOfSongs.isNotEmpty) {
                    schedule.songs = _mapOfSongs.map((e) => widget.playList[e]).toSet();
                  }

                  Navigator.pop(context, schedule);
                }
              });
            }
        ),
      ],
    );
  }

  _isTimeInvalid(String? value) {

    if (value != null) {

      if (value.length < 4) {
        return true;
      }

      var timeArray = value.split(":");
      var hourValue = int.parse(timeArray[0]);
      if (hourValue < 0 || hourValue > 23) {
        return true;
      }

      var minuteValue = int.parse(timeArray[1]);
      if (minuteValue < 0 || minuteValue > 59) {
        return true;
      }
    }

    return false;
  }

  _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      initialTime: _getSelectedTime(controller),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
      });
    }
  }

  TimeOfDay _getSelectedTime(TextEditingController controller) {
    var timeOfDay = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      var timeSelected = controller.text.split(':');
      timeOfDay = TimeOfDay(hour: int.parse(timeSelected[0]), minute: int.parse(timeSelected[1]));
    }

    return timeOfDay;
  }

}

class CheckboxListTileDialog extends StatefulWidget {

  const CheckboxListTileDialog({Key? key, required this.playList, required this.mapOfSongs, this.scheduleEdit}): super(key: key);

  final Map<String, AudioInfo> playList;
  final Set<String> mapOfSongs;
  final Schedule? scheduleEdit;

  @override
  _CheckboxListTileDialogState createState() => _CheckboxListTileDialogState();
}

class _CheckboxListTileDialogState extends State<CheckboxListTileDialog> {

  @override
  void initState(){
    super.initState();

    if (widget.scheduleEdit != null) {
      var songs2 = widget.scheduleEdit?.songs;
      for (var audioInfoSaved in songs2!) {
        if (audioInfoSaved != null) {
          widget.mapOfSongs.add(audioInfoSaved.title);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: 8,
      runSpacing: 12,
      children: widget.playList.keys.map((e) =>
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              title: Text(e),
              value: widget.mapOfSongs.contains(e),
              onChanged: (bool? value) {
                setState(() {
                  if (value!) {
                    widget.mapOfSongs.add(e);
                  } else {
                    widget.mapOfSongs.remove(e);
                  }
                });
              }
          )
      ).toList(growable: false),
    );
  }
}

class Schedule {
  int? id;
  String start;
  String end;
  bool selected = false;
  int? startInt;
  int? endInt;
  Set<AudioInfo?> songs = {};

  Schedule({required this.id, required this.start, required this.end});

  toJSONEncodable() {
    Map<String, dynamic> m = Map();

    m['id'] = id;
    m['start'] = start;
    m['end'] = end;
    m['songs'] = songs.map((e) => toJSONEncodableAudioInfo(e!)).toList();

    return m;
  }

  toJSONEncodableAudioInfo(AudioInfo audioInfo) {
    Map<String, dynamic> m = Map();

    m['url'] = audioInfo.url;
    m['title'] = audioInfo.title;
    m['desc'] = audioInfo.desc;
    m['coverUrl'] = audioInfo.coverUrl;

    return m;
  }

  toString() {
    return 'id:' + id.toString() + ', start:' + start + ', end:' + end;
  }
}

class ScheduleList {
  List<Schedule> schedules = List.empty(growable: true);

  toJSONEncodable() {
    return schedules.map((schedule) {
      return schedule.toJSONEncodable();
    }).toList();
  }
}
