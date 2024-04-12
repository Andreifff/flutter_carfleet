const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.checkTaxDates = functions.pubsub.schedule(
    "every 4 hours").onRun(async (context) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tenDaysLater = new Date(today);
  tenDaysLater.setDate(tenDaysLater.getDate() + 10);
  const threeDaysLater = new Date(today);
  threeDaysLater.setDate(threeDaysLater.getDate() + 3);

  const documentsToCheck = ["annualTax", "insurance", "nextServiceInterval"];
  const promises = []; // Define promises array to collect all send operations

  for (const document of documentsToCheck) {
    const carsSnapshot = await admin.firestore().collection("cars")
        .where(document, ">=", today)
        .where(document, "<=", tenDaysLater)
        .get();

    carsSnapshot.forEach((doc) => {
      const car = doc.data();
      const dueDate = car[document] ? car[document].toDate() : null;
      const dueDateString = dueDate ? dueDate.toISOString().split("T")[0] :
       "soon";
      let notificationBody = `Your ${document} for ${car.make} ${car.model} '+
      +'is due on ${dueDateString}.`;

      if (new Date(car[document]) <= threeDaysLater) {
        notificationBody = `Urgent: Your ${document} for'+
        +' ${car.make} ${car.model} is due in less than 3 days '+'
        on ${dueDateString}.`;
      }

      const payload = {
        notification: {
          title: `${document.charAt(0).toUpperCase() + document.slice(1)}
           Reminder`,
          body: notificationBody,
        },
        token: car.userFcmToken};

      if (payload.token) { // Ensure there's a token before trying to send
        promises.push(admin.messaging().send(payload));
      }
    });
  }

  return Promise.all(promises);
});
