import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.api, required this.token, required this.orderID, required this.userID});
  final ApiClient api; final String token; final String orderID; final String userID;
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController(); List<ChatMessage> _messages=[]; bool _loading=true;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_input.dispose();super.dispose();}
  Future<void> _load() async { try {_messages=await widget.api.messages(widget.token,widget.orderID);} finally {if(mounted)setState(()=>_loading=false);} }
  Future<void> _send() async { final body=_input.text.trim(); if(body.isEmpty)return; _input.clear(); try { await widget.api.sendMessage(widget.token,widget.orderID,body); await _load(); } catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Sargyt çaty')),body:Column(children:[const Padding(padding:EdgeInsets.all(12),child:Text('Telefon belgileri gizlin saklanýar.',style:TextStyle(color:Color(0xFF64748B)))),Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.builder(reverse:true,padding:const EdgeInsets.all(16),itemCount:_messages.length,itemBuilder:(context,index){final m=_messages[_messages.length-1-index];final mine=m.senderID==widget.userID;return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:mine?const Color(0xFF4F46E5):Colors.white,borderRadius:BorderRadius.circular(16)),child:Text(m.body,style:TextStyle(color:mine?Colors.white:const Color(0xFF16213E))));})),SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:_input,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Habar ýazyň'))),const SizedBox(width:8),IconButton.filled(onPressed:_send,icon:const Icon(Icons.send_rounded))])))]));
}
