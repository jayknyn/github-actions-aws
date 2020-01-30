const express = require('express');
const app = express();
app.listen(3000, (err, res) => {
  if (err) {
    console.log('server error: ', err);
  } else {
    console.log('Server running in aisle 3000');
  }
});
app.use(express.static('dist'));
