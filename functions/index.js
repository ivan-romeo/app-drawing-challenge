// functions/index.js

const admin = require('firebase-admin');
// Importiamo il trigger Realtime v2
const { onValueCreated } = require('firebase-functions/v2/database');

admin.initializeApp({
  // Dobbiamo specificare il tuo databaseURL qui
  databaseURL: 'https://applicazionetestfirebase-7b312-default-rtdb.europe-west1.firebasedatabase.app'
});

exports.onGuessCreated = onValueCreated(
  {
    // path dentro al tuo RTDB
    ref: '/rooms/{roomId}/guesses/{guessId}',
    // regione in cui è allocato il tuo RTDB
    region: 'europe-west1',
    // l'ID dell'istanza Realtime (senza ".firebaseio.com")
    instance: 'applicazionetestfirebase-7b312-default-rtdb',
  },
  async (event) => {
    const guess = event.data?.val();
    if (!guess?.correct) return null;

    const roomId    = event.params.roomId;
    const playerUid = guess.userId;
    const firestore = admin.firestore();
    const roomRef   = firestore.doc(`rooms/${roomId}`);

    return firestore.runTransaction(tx =>
      tx.get(roomRef).then(doc => {
        if (!doc.exists) return;
        const players  = doc.data().players || {};
        const oldScore = players[playerUid]?.score   || 0;
        tx.update(roomRef, {
          [`players.${playerUid}.score`]: oldScore + 1
        });
      })
    );
  }
);
